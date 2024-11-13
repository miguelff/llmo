class Report < ApplicationRecord
    VALID_ADVANCED_SETTINGS = %w[cohort exhaustiveness advanced]
    EXHAUSTIVENESS_OPTIONS = [ :brief, :standard, :thorough ]

    validates :query, presence: true
    validate :validate_advanced_settings_keys
    enum :status, %i[pending processing completed failed]

    before_create :maybe_assign_id
    after_create_commit :process_report
    after_update_commit :refresh_report_status
    has_one :result, dependent: :destroy
    scope :recent, -> { order(created_at: :desc).limit(10) }

    def update_progress(params)
      attrs = { progress_percent: params[:percentage] }

      if params[:message].present?
        details = self.progress_details || []
        details << params[:message]
        attrs[:progress_details] = details
      end

      unless params[:result].nil?
        attrs[:status] = :completed
        attrs[:result] = Result.new(json: params[:result])
      end

      update(attrs)
    end

    private

    def validate_advanced_settings_keys
        return if advanced_settings.blank?
        invalid_keys = advanced_settings.keys - VALID_ADVANCED_SETTINGS

        if invalid_keys.any?
            errors.add(:advanced_settings, "can only contain the following keys: #{allowed_keys.join(', ')}")
        end

        if advanced_settings[:exhaustiveness].present? && !EXHAUSTIVENESS_OPTIONS.include?(advanced_settings[:exhaustiveness])
            errors.add(:advanced_settings, "exhaustiveness must be one of: #{EXHAUSTIVENESS_OPTIONS.join(', ')}")
        end
    end

    def maybe_assign_id
        self.id = SecureRandom.uuid if self.id.blank?
    end

    def process_report
        ProcessReportJob.perform_later(self)
    end

    def refresh_report_status
        if self.completed?
            Turbo::StreamsChannel.broadcast_replace_to(
                self,
                target: "report-status",
                partial: "turbo/refresh",
                locals: { report: self }
            )
        else
        Turbo::StreamsChannel.broadcast_replace_to(
            self,
            target: "report-status",
            partial: "reports/status",
            locals: {
            report: self
            })
        end
    end
end
