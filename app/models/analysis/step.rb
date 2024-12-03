class Analysis::Step < ApplicationRecord
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

    belongs_to :report
    after_initialize :set_default_values
    class_attribute :model, :temperature

    def self.perform_if_needed(report, **args)
        step = self.find_or_initialize_by(report: report)
        args.each do |key, value|
            step.send("#{key}=", value)
        end

        unless step.succeeded?
            report.update_progress(message: "Resoning on input")
            if step.perform_with_retry
                if step.save
                    Rails.logger.info "[Report #{report.id}] Step #{step.type} completed: #{step.result.inspect}"
                else
                    step.error = step.errors.full_messages.join(", ")
                    Rails.logger.error "[Report #{report.id}] Step #{step.type} failed: #{step.error}"
                end
            end
        else
            Rails.logger.info "[Report #{report.id}] Step #{step.type} already completed: #{step.result.inspect}"
        end

        Result.new(step)
    end

    def perform_and_save
        self.perform_with_retry && self.save
    end

    def perform
        raise "Not implemented"
    end

    def perform_with_retry(attempt = 1)
        self.attempt = attempt
        self.perform
    rescue NameError, ArgumentError => e
        Rails.logger.error("Error performing #{self.class.name}: #{e.message}, unrecoverable. Not retrying.")
        self.error = e.message
        raise
    rescue => e
        if attempt < MAX_ATTEMPT_COUNT
            Rails.logger.error("Error performing #{self.class.name}: #{e.message}. Retrying (#{attempt + 1}/#{MAX_ATTEMPT_COUNT})...")
            self.error = e.message
            backoff(attempt)
            perform_with_retry(attempt + 1)
        else
            Rails.logger.error("Error performing #{self.class.name}: #{e.message}. No more retries left.")
            self.error = e.message
            raise
        end
    end

    def succeeded?
        self.error.nil? && self.result.present?
    end

    private

    def set_default_values
        self.provider ||=  "openai"
        self.model ||= (self.class.model || "gpt-4o-mini")
        self.temperature ||= (self.class.temperature || 0.0)
    end

    def backoff(attempt)
        sleep(attempt ** 2)
    end
end

Dir[File.join(__dir__, "*.rb")].each do |file|
  require file unless file == __FILE__
end
