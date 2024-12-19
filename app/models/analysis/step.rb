class Analysis::Step < ApplicationRecord
    enum :status, pending: "pending", performing: "performing", finished: "finished", failed: "failed"
    belongs_to :analysis, class_name: "Analysis::Record"

    MAX_ATTEMPT_COUNT = 3

    class_attribute :model, :temperature
    validate :valid_input, if: -> { self.new_record? }

    def valid_input
        true
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

        step
    end

    def perform_later
        if pending!
            AnalysisStepJob.perform_later(self)
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
