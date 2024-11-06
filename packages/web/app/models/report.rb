class Report < ApplicationRecord
    validates :query, presence: true
    validate :validate_advanced_settings_keys
    VALID_ADVANCED_SETTINGS = %w[cohort advanced]
    enum :status, %i[pending processing completed failed]

    before_create :maybe_assign_id
    after_create_commit :process_report

    private

    def validate_advanced_settings_keys
      return if advanced_settings.blank?
      invalid_keys = advanced_settings.keys - VALID_ADVANCED_SETTINGS
      if invalid_keys.any?
        errors.add(:advanced_settings, "can only contain the following keys: #{allowed_keys.join(', ')}")
      end
    end

    def maybe_assign_id
        self.id = SecureRandom.uuid if self.id.blank?
    end

    def process_report
        ProcessReportJob.perform_later(self)
    end
end
