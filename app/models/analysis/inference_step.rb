module Analysis::InferenceStep
    extend ActiveSupport::Concern

    included do
        class_attribute :output_schema, :system_prompt
        after_initialize :set_default_values
    end

    module ClassMethods
        def schema(schema, &block)
            self.output_schema = schema
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
            messages.unshift({ role: :system, content: self.class.system_prompt })
        end

        client.parse(
            model: self.model,
            temperature: self.temperature,
            messages: [ { role: "user", content: "Give me a random output that matches the schema" } ],
            response_format: self.output_schema
        )
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
