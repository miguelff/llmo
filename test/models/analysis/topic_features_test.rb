require "test_helper"

class Analysis::TopicFeaturesTest < ActiveSupport::TestCase
  test "OverarchingTerm: when topic is a product" do
    VCR.use_cassette("analysis/topic_features/overarching_term/product") do
      query = "What are the best electric cars in the market?"
      topic = { "type" => "product", "brand" => "Tesla", "product" => "Model 3" }
      features = Analysis::TopicFeatures.new(**params(topic, query))
      assert_equal "electric cars", features.overarching_term
    end
  end

  test "OverarchingTerm: when topic is a brand" do
    VCR.use_cassette("analysis/topic_features/overarching_term/brand") do
      query = "What are the best electric cars in the market?"
      topic = { "type" => "brand", "brand" => "Volkswagen" }
      features = Analysis::TopicFeatures.new(**params(topic, query))
      assert_equal "electric cars", features.overarching_term
    end
  end

  test "OverarchingTerm: when topic is a brand, but the query doesn't seem to be about brands" do
    VCR.use_cassette("analysis/topic_features/overarching_term/brand_and_query") do
      query = "What is the most affordable car you can buy if you are a retired woman with grand children?"
      topic = { "type" => "brand", "brand" => "Volkswagen" }
      features = Analysis::TopicFeatures.new(**params(topic, query))
      assert_equal "affordable family cars", features.overarching_term
    end
  end

  test "Attributes" do
    VCR.use_cassette("analysis/topic_features/attributes") do
      query = "What are the most affordable cars in the market?"
      # Inferred by a previous step of the pipeline (from "Volkswagen Polo" entered into the brand_info input field)
      topic = { "type" => "product", "brand" => "Volkswagen", "product" => "Polo" }
      features = Analysis::TopicFeatures.new(**params(topic, query))
      expected_attributes = [
        {
          "name" => "Price",
          "definition" => "The cost of the vehicle, including base price and any additional fees.",
          "why" => "Price is a critical factor for consumers in the affordable cars category, as it directly influences purchasing decisions and market competitiveness."
        },
        {
          "name" => "Fuel Efficiency",
          "definition" => "The distance a vehicle can travel per unit of fuel, typically measured in miles per gallon (MPG).",
          "why" => "Fuel efficiency is important for budget-conscious consumers, as it affects long-term ownership costs and overall value."
        },
        {
          "name" => "Safety Ratings",
          "definition" => "Evaluations of a vehicle's safety features and performance in crash tests, often provided by organizations like the NHTSA or IIHS.",
          "why" => "Safety ratings are crucial for consumers looking for reliable and secure vehicles, especially in the affordable segment where families may prioritize safety."
        },
        {
          "name" => "Warranty and Service Plans",
          "definition" => "The coverage provided for repairs and maintenance, including the duration and extent of the warranty.",
          "why" => "A strong warranty can enhance consumer confidence and perceived value, making it a key differentiator among affordable car options."
        },
        {
          "name" => "Resale Value",
          "definition" => "The estimated value of a vehicle when it is sold after a certain period of ownership.",
          "why" => "Resale value impacts the total cost of ownership and is a significant consideration for buyers in the affordable market, as it affects long-term financial planning."
        }
      ]
      assert_equal expected_attributes, JSON.parse(features.attributes.to_json)
    end
  end

  def params(topic, query)
    begin
      report = Report.create!(query: query, owner: users(:jane))

      {
        entities: entities,
        report: report,
        topic: topic,
        language: "en"
      }
    end
  end


  def entities
    {
        "brands" => [
          {
            "name" => "Volkswagen",
            "links" => [
              "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap/"
            ],
            "positions" => [ 1 ],
            "products" => [ "Volkswagen VW ID.7" ]
          },
          {
            "name" => "NIO",
            "links" => [
              "https://www.autoscout24.de/informieren/ratgeber/auto-sicherheit/ncap-sicherste-autos/"
            ],
            "positions" => [ 2 ],
            "products" => [ "NIO ET5" ]
          },
          {
            "name" => "Smart",
            "links" => [
              "https://www.finn.com/de-DE/auto/bestenliste/sicherstes-auto"
            ],
            "positions" => [ 3 ],
            "products" => [ "Smart #3" ]
          },
          {
            "name" => "Tesla",
            "links" => [
              "https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos"
            ],
            "positions" => [ 4 ],
            "products" => [ "Tesla Model 3", "Tesla Model Y" ]
          },
          {
            "name" => "Volvo",
            "links" => [
              "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap-2022/"
            ],
            "positions" => [ 5 ],
            "products" => [ "Volvo XC60", "Volvo XC90" ]
          }
        ],
        "products" => [
          {
            "name" => "Volkswagen VW ID.7",
            "links" => [
              "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap/"
            ],
            "positions" => [ 1 ],
            "brand" => "Volkswagen"
          },
          {
            "name" => "NIO ET5",
            "links" => [
              "https://www.autoscout24.de/informieren/ratgeber/auto-sicherheit/ncap-sicherste-autos/"
            ],
            "positions" => [ 2 ],
            "brand" => "NIO"
          },
          {
            "name" => "Smart #3",
            "links" => [
              "https://www.finn.com/de-DE/auto/bestenliste/sicherstes-auto"
            ],
            "positions" => [ 3 ],
            "brand" => "Smart"
          },
          {
            "name" => "Tesla Model 3",
            "links" => [
              "https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos"
            ],
            "positions" => [ 4 ],
            "brand" => "Tesla"
          },
          {
            "name" => "Tesla Model Y",
            "links" => [
              "https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos"
            ],
            "positions" => [ 4 ],
            "brand" => "Tesla"
          },
          {
            "name" => "Volvo XC60",
            "links" => [
              "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap-2022/"
            ],
            "positions" => [ 5 ],
            "brand" => "Volvo"
          },
          {
            "name" => "Volvo XC90",
            "links" => [
              "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap-2022/"
            ],
            "positions" => [ 5 ],
            "brand" => "Volvo"
          }
        ],
        "links" => {
          "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap/" => {
            "product_hits" => 1,
            "brand_hits" => 1,
            "orphan_hits" => 1,
            "brands" => [ "Volkswagen" ],
            "products" => [ "Volkswagen VW ID.7" ]
          },
          "https://www.autoscout24.de/informieren/ratgeber/auto-sicherheit/ncap-sicherste-autos/" => {
            "product_hits" => 1,
            "brand_hits" => 1,
            "orphan_hits" => 1,
            "brands" => [ "NIO" ],
            "products" => [ "NIO ET5" ]
          },
          "https://www.finn.com/de-DE/auto/bestenliste/sicherstes-auto" => {
            "product_hits" => 1,
            "brand_hits" => 1,
            "orphan_hits" => 1,
            "brands" => [ "Smart" ],
            "products" => [ "Smart #3" ]
          },
          "https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos" => {
            "product_hits" => 2,
            "brand_hits" => 1,
            "orphan_hits" => 1,
            "brands" => [ "Tesla" ],
            "products" => [ "Tesla Model 3", "Tesla Model Y" ]
          },
          "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap-2022/" => {
            "product_hits" => 2,
            "brand_hits" => 1,
            "orphan_hits" => 1,
            "brands" => [ "Volvo" ],
            "products" => [ "Volvo XC60", "Volvo XC90" ]
          }
        }
      }
  end
end
