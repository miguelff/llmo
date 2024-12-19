require "test_helper"

class StepTest < ActiveSupport::TestCase
    class TestStep < Analysis::Step
        attr_accessor :error, :pass_at_attempt, :callback, :backoff_count, :secs_slept

        def valid_input
            true
        end

        def self.build(e, pass_at_attempt: 2, callback: nil)
            new.tap do |step|
                step.callback = callback
                step.error = e
                step.pass_at_attempt = pass_at_attempt
                step.secs_slept = []
            end
        end

        def perform
            callback.call(self) if callback.present?
            raise error unless attempt == pass_at_attempt
        end

        def sleep(secs)
            secs_slept << secs
        end
    end


    test "Retries: perform with retry for unrecoverable error" do
        step = TestStep.build(NameError.new)
        assert_raises(NameError) { step.perform_with_retry }
        assert_equal 1, step.attempt
        assert_equal [], step.secs_slept
    end

    test "Retries:perform with retry for recoverable error" do
        step = TestStep.build(StandardError.new("This is a test error"))
        assert_nothing_raised { step.perform_with_retry }
        assert_equal 2, step.attempt
        assert_equal [ 1 ], step.secs_slept
    end

    test "Retries:perform with retry for recoverable error, after it errored too many times" do
        step = TestStep.build(StandardError.new("This is a test error"), pass_at_attempt: 4)
        assert_raises(StandardError, /This is a test error/) { step.perform_with_retry }
        assert_equal Analysis::Step::MAX_ATTEMPT_COUNT, step.attempt
        assert_equal [ 1, 4 ], step.secs_slept
    end


    test "Retries:perform reset retry count when invoked again" do
        times_invoked = 0
        step = TestStep.build(StandardError.new("This is a test error"), pass_at_attempt: 4, callback: ->(step) { times_invoked+=1 })
        assert_raises(StandardError, /This is a test error/) { step.perform_with_retry }
        assert_equal 3, times_invoked

        # We reset the counter of times invoked
        times_invoked = 0
        # and in spite of the previous attempt, we invoke again
        assert_equal 3, step.attempt
        assert_raises(StandardError, /This is a test error/) { step.perform_with_retry }
        # and we expect the perform method to be retried again
        assert_equal 3, times_invoked
        assert_equal [ 1, 4, 1, 4 ], step.secs_slept
    end
end
