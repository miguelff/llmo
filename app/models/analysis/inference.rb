module Analysis::Inference
    extend ActiveSupport::Concern

    included do
        class_attribute :output_schema, :system_prompt, :model, :temperature
        attr_writer :language
    end

    module ClassMethods
        def tools(&block)
            self.available_tools = block.call
        end

        def schema(&block)
            self.output_schema = OpenAI::StructuredOutputs::Schema.new(&block)
        end

        def system(prompt)
            if prompt.is_a?(Hash)
                self.system_prompt = prompt
            else
                self.system_prompt = { Analysis::DEFAULT_LANGUAGE => prompt }
            end
        end
    end

    def language
        @language ||= Analysis::DEFAULT_LANGUAGE
    end

    def client
        OpenAI::StructuredOutputs::OpenAIClient.new
    end

    def chat(user_message)
        messages = [ { role: :user, content: user_message } ]

        if system_prompt.present?
            language_specific_prompt = system_prompt[self.language.to_sym] || system_prompt[Analysis::DEFAULT_LANGUAGE]
            raise "No system prompt defined for language #{self.language}" if language_specific_prompt.blank?
            messages.unshift({ role: :system, content: language_specific_prompt })
        end

        parameters = self.parameters(messages)
        Rails.logger.debug("Sending message to #{self.provider} (#{self.model}): #{parameters.inspect}")
        result = if self.output_schema.present?
            parameters[:response_format] = self.output_schema
            client.parse(**parameters)
        else
            client.chat(parameters: parameters)
        end
        Rails.logger.debug("Received response from #{self.provider} (#{self.model}): #{result.inspect}")
        result
    end

    def assist(user_message, tools: [])
        instructions = system_prompt && (system_prompt[self.language.to_sym] || system_prompt[Analysis::DEFAULT_LANGUAGE]) || "You are a helpful assistant"

        Rails.logger.debug("Creating assistant with model #{model}, and instructions #{instructions.truncate_words(10)}")
        model = Langchain::LLM::OpenAI.new(
            api_key: Rails.application.credentials.processor[:OPENAI_API_KEY],
            default_options: {
                model: self.model,
                temperature: self.temperature
            }
        )
        assistant = Langchain::Assistant.new(
            llm: model,
            instructions: instructions,
            tools: tools
        )
        assistant.add_message(content: user_message)
        assistant.run(auto_tool_execution: true)
    end

    def perform_and_save
        self.perform && self.save
    end

    private

    def parameters(messages)
        parameters = {
            model: self.model,
            temperature: self.temperature,
            messages: messages
        }

        parameters
    end
end
