module Analysis::InferenceStep
    extend ActiveSupport::Concern

    included do
        class_attribute :output_schema, :system_prompt
        after_initialize :set_default_values
        attribute :language, :string, default: Analysis::DEFAULT_LANGUAGE
    end

    module ClassMethods
        def schema(schema)
            if schema.is_a?(String)
                self.output_schema = { language: Analysis::DEFAULT_LANGUAGE, schema: schema }
            else
                self.output_schema = schema
            end
        end

        def system(prompt)
            self.system_prompt = prompt
        end
    end

    def client
        OpenAI::StructuredOutputs::OpenAIClient.new
    end

    def structured_inference(message)
        messages = [ { role: :user, content: message } ]

        if self.class.system_prompt.present?
            language_specific_prompt = self.class.system_prompt[self.language]
            raise "No system prompt defined for language #{self.language}" if language_specific_prompt.blank?
            messages.unshift({ role: :system, content: language_specific_prompt })
        end

        Rails.logger.debug("Sending message to #{self.provider} (#{self.model}): #{messages.inspect}")
        result = client.parse(
            model: self.model,
            temperature: self.temperature,
            messages: messages,
            response_format: self.output_schema
        )
        Rails.logger.debug("Received response from #{self.provider} (#{self.model}): #{result.inspect}")
        result
    end

    def perform_and_save
        self.perform && self.save
    end

    private

    def set_default_values
        self.provider ||= "openai"
        self.model ||= "gpt-4o-mini"
        self.temperature ||= 0.0
    end
end
