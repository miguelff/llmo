module Analysis::InferenceStep
    extend ActiveSupport::Concern

    included do
        class_attribute :output_schema, :system_prompt, :available_tools
        after_initialize :set_default_values
        attribute :language, :string, default: Analysis::DEFAULT_LANGUAGE
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

    def client
        OpenAI::StructuredOutputs::OpenAIClient.new
    end

    def tool_choice
        "required" if available_tools.present?
    end

    def valid_tool_names
        @valid_tool_names ||= self.available_tools.select { |tool| tool[:function].present? }.map { |tool| tool[:function][:name] }
    end

    def chat(user_message)
        messages = [ { role: :user, content: user_message } ]

        if system_prompt.present?
            language_specific_prompt = system_prompt[self.language.to_sym] || system_prompt[Analysis::DEFAULT_LANGUAGE]
            raise "No system prompt defined for language #{self.language}" if language_specific_prompt.blank?
            messages.unshift({ role: :system, content: language_specific_prompt })
        end

        response = send_messages(messages)

        message = response.dig("choices", 0, "message")
        if message.present? && message["role"] == "assistant" && message["tool_calls"]
            valid_tools = self.available_tools.select { |tool| tool[:function].present? }.map { |tool| tool[:function][:name] }
            message["tool_calls"].each do |tool_call|
                tool_call_id = tool_call.dig("id")
                function_name = tool_call.dig("function", "name")
                if !valid_tools.include?(function_name)
                    raise "Invalid tool call: #{function_name}, valid tools: #{valid_tools.inspect}"
                end

                function_args = JSON.parse(
                tool_call.dig("function", "arguments"),
                    { symbolize_names: true },
                )
                function_response = send(function_name, **function_args)
                # For a subsequent message with the role "tool", OpenAI requires the preceding message to have a tool_calls argument.
                messages << message

                messages << {
                    tool_call_id: tool_call_id,
                    role: "tool",
                    name: function_name,
                    content: function_response
                }  # Extend the conversation with the results of the functions
            end

            result = send_messages(messages, omit_tool_calls: true)
            return result
        end

        response
    end

    def send_messages(messages, omit_tool_calls: false)
        parameters = self.parameters(messages, omit_tool_calls: omit_tool_calls)
        parameters[:response_format] = self.output_schema

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

    def perform_and_save
        self.perform && self.save
    end

    private

    def parameters(messages, omit_tool_calls: false)
        parameters = {
            model: self.model,
            temperature: self.temperature,
            messages: messages
        }

        unless omit_tool_calls
            parameters[:tools] = available_tools unless available_tools.blank?
            parameters[:tool_choice] = tool_choice unless tool_choice.blank?
        end

        parameters
    end

    def set_default_values
        self.provider ||= "openai"
        self.model ||= "gpt-4o-mini"
        self.temperature ||= 0.0
    end
end
