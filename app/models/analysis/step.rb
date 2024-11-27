class Analysis::Step < ApplicationRecord
    belongs_to :report
    after_initialize :set_default_values

    def succeeded?
        self.error.nil? && self.result.present?
    end

    private

    def set_default_values
        self.provider ||=  "openai"
        self.model ||= (self.class.model || "gpt-4o-mini")
        self.temperature ||= (self.class.temperature || 0.0)
    end
end
