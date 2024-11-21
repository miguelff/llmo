class Analysis::LanguageDetection < ApplicationRecord
    include Analysis::InferenceStep

    belongs_to :report

    schema do
        string :language, enum: Analysis::SUPPORTED_LANGUAGES, description: "The detected language of the input text"
    end

    system <<-EOF.squish
        You are an assistant specialized in language detection.
        Your task is to analyze text and determine its language. Return only the ISO-639-2
        three-letter language code (e.g. 'eng' for English, 'spa' for Spanish, etc.).
        If the language cannot be determined, return 'und' for undefined.

        We only support a set of languages:

        #{Analysis::SUPPORTED_LANGUAGES.join(", ")}

        if the code is for a different language, return 'und' for undefined.
    EOF

    def perform
        language = structured_inference("Input: #{self.report.query} #{self.report.cohort.presence}")
        unless language.refusal.present?
            self.language = language.parsed.language
        else
            self.error = "Language detection refused: #{language.refusal}, defaulting to 'eng' language"
            Rails.logger.error(self.error)
            self.language = "eng"
        end

        true
    end
end
