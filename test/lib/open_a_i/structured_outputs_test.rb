require "test_helper"

class OpenAI::StructuredOutputsTest < ActiveSupport::TestCase
  test "client returns JSON matching simple schema" do
    friend = OpenAI::StructuredOutputs::Schema.new("friends") do
      string :name
    end

    # Define a simple schema with one field
    schema = OpenAI::StructuredOutputs::Schema.new("simple") do
      string :greeting
      number :age
      array :friends, items: friend
    end

    client = OpenAI::StructuredOutputs::OpenAIClient.new

    response = client.parse(
      model: "gpt-4o",
      messages: [
        { role: "user", content: "Give me a random output that matches the schema" }
      ],
      response_format: schema
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
