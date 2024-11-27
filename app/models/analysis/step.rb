class Analysis::Step < ApplicationRecord
    COSTS = {
        inference: 4,
        search: 2,
        download: 1
    }

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

Dir[File.join(__dir__, "*.rb")].each do |file|
  require file unless file == __FILE__
end
