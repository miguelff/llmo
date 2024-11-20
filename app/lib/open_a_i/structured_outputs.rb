require "json"
require "dry-schema"
require "openai"
require "ostruct"

module OpenAI
  module StructuredOutputs
    # Schema class for defining JSON schemas
    class Schema
      MAX_OBJECT_PROPERTIES = 100
      MAX_NESTING_DEPTH = 5

      def initialize(name = nil, &block)
        # Use the provided name or derive from class name
        @name = name || self.class.name.split("::").last.downcase
        # Initialize the base schema structure
        @schema = {
          type: "object",
          properties: {},
          required: [],
          additionalProperties: false,
          strict: true
        }
        @definitions = {}
        # Execute the provided block to define the schema
        instance_eval(&block) if block_given?
        validate_schema
      end

      # Convert the schema to a hash format
      def to_hash
        {
            name: @name,
            description: "Schema for the structured response",
            schema: @schema.merge({ "$defs" => @definitions })
        }
      end

      private

      # Define a string property
      def string(name, enum: nil, description: nil)
          add_property(name, { type: "string", enum: enum, description: description }.compact)
      end

      # Define a number property
      def number(name)
        add_property(name, { type: "number" })
      end

      # Define a boolean property
      def boolean(name)
        add_property(name, { type: "boolean" })
      end

      # Define an object property
      def object(name, &block)
        properties = {}
        required = []
        Schema.new.tap do |s|
          s.instance_eval(&block)
          properties = s.instance_variable_get(:@schema)[:properties]
          required = s.instance_variable_get(:@schema)[:required]
        end
        add_property(name, { type: "object", properties: properties, required: required, additionalProperties: false })
      end

      # Define an array property
      def array(name, items:)
        add_property(name, { type: "array", items: items })
      end

      # Define an anyOf property
      def any_of(name, schemas)
        add_property(name, { anyOf: schemas })
      end

      # Define a reusable schema component
      def define(name, &block)
        @definitions[name] = Schema.new(&block).instance_variable_get(:@schema)
      end

      # Reference a defined schema component
      def ref(name)
        { "$ref" => "#/$defs/#{name}" }
      end

      # Add a property to the schema
      def add_property(name, definition)
        @schema[:properties][name] = definition
        @schema[:required] << name
      end

      # Validate the schema against defined limits
      def validate_schema
        properties_count = count_properties(@schema)
        raise "Exceeded maximum number of object properties" if properties_count > MAX_OBJECT_PROPERTIES

        max_depth = calculate_max_depth(@schema)
        raise "Exceeded maximum nesting depth" if max_depth > MAX_NESTING_DEPTH
      end

      # Count the total number of properties in the schema
      def count_properties(schema)
        return 0 unless schema.is_a?(Hash) && schema[:properties].present?
        count = schema[:properties].size
        schema[:properties].each_value do |prop|
          count += count_properties(prop)
        end
        count
      end

      # Calculate the maximum nesting depth of the schema
      def calculate_max_depth(schema, current_depth = 1)
        return current_depth unless schema.is_a?(Hash) && schema[:properties].present?
        max_child_depth = schema[:properties].values.map do |prop|
          calculate_max_depth(prop, current_depth + 1)
        end.max
        [ current_depth, max_child_depth ].max
      end
    end

    # Client class for interacting with OpenAI API
    class OpenAIClient
      def initialize
        OpenAI.configure do |config|
          config.access_token = Rails.application.credentials.processor[:OPENAI_API_KEY]
          config.log_errors = true
        end
        @client = OpenAI::Client.new
      end

      # Send a request to OpenAI API and parse the response
      def parse(model:, temperature: 0.0, messages:, response_format:)
        response = @client.chat(
          parameters: {
            model: model,
            messages: messages,
            temperature: temperature,
            response_format: {
              type: "json_schema",
              json_schema: response_format.to_hash
            }
          }
        )
                
        content = JSON.parse(response["choices"][0]["message"]["content"])

        if response["choices"][0]["message"]["refusal"]
          OpenStruct.new(refusal: response["choices"][0]["message"]["refusal"], parsed: nil)
        else
          OpenStruct.new(refusal: nil, parsed: Hashie::Mash.new(content))
        end
      end
    end
  end

  # Example usage: Define a schema for math reasoning
  class MathReasoning < StructuredOutputs::Schema
    def initialize
      super do
        define :step do
          string :explanation
          string :output
        end
        array :steps, items: ref(:step)
        string :final_answer
      end
    end
  end
end
