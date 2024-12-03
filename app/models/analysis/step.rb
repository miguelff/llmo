class Analysis::Step < ApplicationRecord
    MAX_ATTEMPT_COUNT = 3

    belongs_to :report
    after_initialize :set_default_values
    class_attribute :model, :temperature

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
