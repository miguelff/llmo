require "test_helper"

class OpenAI::StructuredOutputsTest < ActiveSupport::TestCase
  test "client returns JSON matching simple schema" do
    class Response < OpenAI::StructuredOutputs::Schema
      def initialize
        super("foo") do
          define :friend do
            string :name
          end
          array :friends, items: ref(:friend)
          string :greeting
          number :age
        end
      end
    end

    client = OpenAI::StructuredOutputs::OpenAIClient.new

    VCR.use_cassette("structured_outputs") do
        response = client.parse(
          model: "gpt-4o",
          messages: [
            { role: "user", content: "Give me a random output that matches the schema" }
          ],
          response_format: Response.new
      )

        assert_nil response.refusal
        assert response.parsed.is_a?(Hash)
        assert response.parsed["greeting"].is_a?(String)
        assert response.parsed["age"].is_a?(Numeric)
        assert response.parsed["friends"].is_a?(Array)
        response.parsed["friends"].each do |friend|
          assert friend.is_a?(Hash)
          assert friend["name"].is_a?(String)
        end
    end
  end
end
