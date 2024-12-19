class Analysis::Step < ApplicationRecord
    enum :status, pending: "pending", performing: "performing", finished: "finished", failed: "failed"

    belongs_to :analysis, class_name: "Analysis::Record"

    private_class_method :new

    class Result
        attr_accessor :step, :result, :error

        def initialize(step)
            self.step = step
            self.result = step.result
            self.error = step.error
        end

        def ok?
            self.error.nil? && self.result.present?
        end

        def failed?
            !self.ok?
        end

        def value!
            if self.ok?
                self.result
            else
                raise self.error
            end
        end
    end

    MAX_ATTEMPT_COUNT = 3

    # Syntactic sugar to define analysis inputs
    def self.input(symbol, type, transform: nil, valid_format: nil)
        attribute symbol

        init = ->(args) do
            lambda do |step|
                step.send("#{symbol}=", transform ? transform.call(args[symbol]) : args[symbol])
                step.input = { symbol => step.send(symbol) }
            end
        end

        define_singleton_method(:for) do |args|
            new(analysis: args[:analysis]).tap(&(init.call(args)))
        end

        define_singleton_method(:for_new_analysis) do |args|
            new(analysis: Analysis::Record.create!).tap(&(init.call(args)))
        end

        define_method(:valid_input) do
            value = send(symbol)
            if value.blank?
                errors.add(symbol, "is required")
            elsif !value.is_a?(type)
                errors.add(symbol, "doesn't have the appropriate type")
            elsif valid_format.present? && !valid_format.call(value)
                errors.add(symbol, "doesn't have a valid format")
            end
        end
    end

    class_attribute :model, :temperature
    validate :valid_input, if: -> { self.new_record? }

    def valid_input
        raise "Must be redefined in subclasses"
    end

    def self.perform_if_needed(analysis_id, force: false, **args)
        step = self.find_or_initialize_by(analysis_id: analysis_id)
        args.each do |key, value|
            step.send("#{key}=", value)
        end

        unless force || step.succeeded?
            if step.perform_with_retry
                if step.save
                    Rails.logger.info "[Analysis #{analysis_id}] Step #{step.type} completed: #{step.result.inspect}"
                else
                    step.error = step.errors.full_messages.join(", ")
                    Rails.logger.error "[Analysis #{analysis_id}] Step #{step.type} failed: #{step.error}"
                end
            end
        else
            Rails.logger.info "[Analysis #{analysis_id}] Step #{step.type} already completed: #{step.result.inspect}"
        end

        Result.new(step)
    end

    def perform_later
        if self.valid?
            Analysis::StepJob.perform_later(self)
        else
            false
        end
    end

    def perform_if_valid
        if self.valid?
            self.perform_with_retry
        else
            false
        end
    end

    def perform
        raise "Not implemented"
    end

    def perform_with_retry(attempt = 1)
        self.update(status: :performing, attempt: attempt)
        self.perform
        self.status = :finished
        self.save
    rescue NameError, ArgumentError => e
        Rails.logger.error("Error performing #{self.class.name}: #{e.message}, unrecoverable. Not retrying.")
        self.update(error: e.message, status: :failed)
        raise
    rescue => e
        if attempt < MAX_ATTEMPT_COUNT
            Rails.logger.error("Error performing #{self.class.name}: #{e.message}. Retrying (#{attempt + 1}/#{MAX_ATTEMPT_COUNT})...")
            self.update(error: e.message)
            backoff(attempt)
            perform_with_retry(attempt + 1)
        else
            Rails.logger.error("Error performing #{self.class.name}: #{e.message}. No more retries left.")
            self.update(error: e.message, status: "failed")
            raise
        end
    end

    def succeeded?
        self.error.nil? && self.result.present?
    end

    private

    def backoff(attempt)
        sleep(attempt ** 2)
    end
end

Dir[File.join(__dir__, "*.rb")].each do |file|
  require file unless file == __FILE__
end
