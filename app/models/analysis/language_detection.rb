class Analysis::LanguageDetection < Analysis::Step
    include Analysis::Inference

    schema do
        string :language, enum: Analysis::SUPPORTED_LANGUAGES, description: "The detected language of the input text"
    end

    system <<-EOF.promptize
        You are an assistant specialized in language detection.
        Your task is to analyze text and determine its language. Return only the ISO-639-2
        three-letter language code (e.g. 'eng' for English, 'spa' for Spanish, etc.).
        If the language cannot be determined, return 'und' for undefined.

        We only support a set of languages:

        #{Analysis::SUPPORTED_LANGUAGES.join(", ")}

        if the code is for a different language, return 'und' for undefined.
    EOF

    def perform
        res = chat("Input: #{self.report.query} #{self.report.cohort.presence}")
        unless res.refusal.present?
            self.result = res.parsed.language
        else
            self.error = "Language detection refused: #{res.refusal}, defaulting to 'eng' language"
            Rails.logger.error(self.error)
            self.result = "eng"
        end

        true
    end
end
