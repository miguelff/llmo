class Report < ApplicationRecord
    VALID_ADVANCED_SETTINGS = %w[cohort brand_info region]

    VALID_ADVANCED_SETTINGS.each do |key|
        attribute key.to_sym

        define_method(key) do
            advanced_settings&.dig(key)
        end

        define_method("#{key}=") do |value|
            self.advanced_settings ||= {}
            self.advanced_settings[key] = value
        end
    end

    EXHAUSTIVENESS_OPTIONS = [ :brief, :standard, :thorough ]
    ZOMBIE_REPORT_THRESHOLD = 2.minutes

    validates :query, presence: true
    validate :validate_advanced_settings_keys
    enum :status, %i[pending processing completed failed]

    before_create :maybe_assign_id
    after_create_commit :process_later
    after_update_commit :refresh_report_status

    has_one :language_detector_analysis, dependent: :destroy, class_name: "Analysis::LanguageDetector"
    has_one :question_synthesis_analysis, dependent: :destroy, class_name: "Analysis::QuestionSynthesis"
    has_one :question_answering_analysis, dependent: :destroy, class_name: "Analysis::QuestionAnswering"
    has_one :input_classifier_analysis, dependent: :destroy, class_name: "Analysis::InputClassifier"
    has_one :entity_extractor_analysis, dependent: :destroy, class_name: "Analysis::EntityExtractor"
    has_one :competitors_analysis, dependent: :destroy, class_name: "Analysis::Competitors"
    has_one :ranking_analysis, dependent: :destroy, class_name: "Analysis::Ranking"

    has_many :analyses, dependent: :destroy, class_name: "Analysis::Step"

    belongs_to :owner, polymorphic: true

    scope :zombies, -> { where(status: :processing).where("updated_at < ?", ZOMBIE_REPORT_THRESHOLD.ago) }

    scope :recent, -> { order(created_at: :desc).limit(10) }
    scope :owned_by, ->(user) { where(owner: user) }

    def complete_analysis
        update(status: :completed, progress_percent: 100)
    end

    def update_progress(params)
      percentage = params[:percentage]
      message = params[:message]

      attrs = {}
      attrs[:progress_percent] =  percentage if percentage.present?

      if message.present?
        details = self.progress_details || []
        details << message
        attrs[:progress_details] = details
      end

      update(attrs)
    end

    def result
        Result.new(self)
    end

    def retry
        if self.reload.failed? || zombie?
            Rails.logger.info "[Report #{self.id}] Retrying report #{Report.inspect}"
            self.process_later
            true
        else
            false
        end
    end

    def zombie?
       self.processing? && self.updated_at < ZOMBIE_REPORT_THRESHOLD.ago
    end

    def method_missing(method, *args, &block)
        if result.present? && result.respond_to?(method)
            result.send(method, *args, &block)
        else
            super
        end
    end

    def country_code
        return nil if region.blank?
        if country = ISO3166::Country.find_country_by_unofficial_names(region.strip)
            "#{country.languages_official.first.downcase}-#{country.alpha2}"
        end
    end

    def analyses_result(name)
        analyses.find { |a| a.type == name }&.result
    end

    def process_later
        ProcessReportJob.perform_later(self)
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
