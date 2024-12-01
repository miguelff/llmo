require "test_helper"

class Analysis::HelpersTest < ActiveSupport::TestCase
  include Analysis::Helpers

  test "topic_name: when topic is a product with brand" do
    topic = { "type" => "product", "brand" => "Tesla", "product" => "Model 3" }
    assert_equal "Tesla Model 3", topic_name(topic)
  end

  test "topic_name: when topic is a product with brand and brand is part of the product name" do
    topic = { "type" => "product", "brand" => "Tesla", "product" => "Tesla Model 3" }
    assert_equal "Tesla Model 3", topic_name(topic)
  end

  test "topic_name: when topic is a product without brand" do
    topic = { "type" => "product", "product" => "Model 3" }
    assert_equal "Model 3", topic_name(topic)
  end

  test "topic_name: when topic is a brand" do
    topic = { "type" => "brand", "brand" => "Volkswagen" }
    assert_equal "Volkswagen", topic_name(topic)
  end

  test "topic_name: when topic is a product and brand is part of the product name" do
    topic = { "type" => "product", "brand" => "Apple", "product" => "Apple iPhone" }
    assert_equal "Apple iPhone", topic_name(topic)
  end
end
