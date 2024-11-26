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

  test "TermAttributes" do
    VCR.use_cassette("analysis/topic_features/term_attributes") do
      query = "What are the most affordable cars in the market?"
      # Inferred by a previous step of the pipeline (from "Volkswagen Polo" entered into the brand_info input field)
      topic = { "type" => "product", "brand" => "Volkswagen", "product" => "Polo" }
      features = Analysis::TopicFeatures.new(**params(topic, query))
      expected_attributes = [
        {
          "name" => "Price",
          "definition" => "The cost of the vehicle, including base price and any additional fees.",
          "why" => "Price is a critical factor for consumers in the affordable cars category, as it directly impacts their purchasing decision and overall value perception."
        },
        {
          "name" => "Fuel Efficiency",
          "definition" => "The distance a vehicle can travel per unit of fuel, typically measured in miles per gallon (MPG).",
          "why" => "Fuel efficiency is important for budget-conscious consumers, as it affects long-term ownership costs and environmental impact."
        },
        {
          "name" => "Safety Ratings",
          "definition" => "Evaluations of a vehicle's safety performance, often provided by organizations like the National Highway Traffic Safety Administration (NHTSA) or the Insurance Institute for Highway Safety (IIHS).",
          "why" => "Safety ratings are crucial for consumers looking for reliable and secure vehicles, especially for families and first-time buyers."
        },
        {
          "name" => "Warranty and Maintenance Costs",
          "definition" => "The coverage provided by the manufacturer for repairs and the expected costs associated with regular maintenance over time.",
          "why" => "A strong warranty and low maintenance costs can enhance the value proposition of affordable cars, making them more appealing to budget-conscious buyers."
        },
        {
          "name" => "Resale Value",
          "definition" => "The estimated value of a vehicle when it is sold after a certain period of ownership.",
          "why" => "Resale value is important for consumers to consider the long-term financial implications of their purchase, as higher resale values can offset initial costs."
        }
      ]
      assert_equal expected_attributes, JSON.parse(features.term_attributes.to_json)
    end
  end

  test "CompetitionScores" do
      VCR.use_cassette("analysis/topic_features/competition_scores") do
        query = "What are the most affordable cars in the market?"
        topic = { "type" => "product", "brand" => "Volkswagen", "product" => "Polo" }
        features = Analysis::TopicFeatures.new(**params(topic, query))
        assert_equal [
          {
            "name" => "Volkswagen VW ID.7",
            "scores" => [
              { "attribute" => "Price", "score" => "7/10", "reason" => "The ID.7 is competitively priced within the electric vehicle segment, making it accessible for many buyers." },
              { "attribute" => "Fuel Efficiency", "score" => "8/10", "reason" => "As an electric vehicle, the ID.7 offers excellent efficiency, translating to lower running costs." },
              { "attribute" => "Safety Ratings", "score" => "9/10", "reason" => "The ID.7 has received high safety ratings, including 5 stars from Euro NCAP, indicating strong occupant protection." },
              { "attribute" => "Warranty and Service Plans", "score" => "8/10", "reason" => "Volkswagen offers a solid warranty and service plan, enhancing consumer confidence." },
              { "attribute" => "Resale Value", "score" => "7/10", "reason" => "The resale value is expected to be good due to the brand's reputation and demand for electric vehicles." }
            ]
          },
          {
            "name" => "NIO ET5",
            "scores" => [
              { "attribute" => "Price", "score" => "6/10", "reason" => "The ET5 is priced higher than many competitors in the affordable segment, which may limit its appeal." },
              { "attribute" => "Fuel Efficiency", "score" => "7/10", "reason" => "As an electric vehicle, it offers decent efficiency, but charging infrastructure may affect usability." },
              { "attribute" => "Safety Ratings", "score" => "8/10", "reason" => "The ET5 has good safety features and ratings, making it a reliable choice." },
              { "attribute" => "Warranty and Service Plans", "score" => "7/10", "reason" => "NIO provides a competitive warranty, but service availability may vary by region." },
              { "attribute" => "Resale Value", "score" => "6/10", "reason" => "As a newer brand, resale value is uncertain compared to established brands." }
            ]
          },
          {
            "name" => "Smart #3",
            "scores" => [
              { "attribute" => "Price", "score" => "8/10", "reason" => "The Smart #3 is priced affordably, appealing to budget-conscious consumers." },
              { "attribute" => "Fuel Efficiency", "score" => "7/10", "reason" => "As a compact electric vehicle, it offers reasonable efficiency for city driving." },
              { "attribute" => "Safety Ratings", "score" => "7/10", "reason" => "Safety ratings are decent, but may not be as high as larger vehicles." },
              { "attribute" => "Warranty and Service Plans", "score" => "6/10", "reason" => "Warranty offerings are standard, but service network may be limited." },
              { "attribute" => "Resale Value", "score" => "5/10", "reason" => "Resale value may be lower due to the niche market of small electric vehicles." }
            ]
          },
          {
            "name" => "Tesla Model 3",
            "scores" => [
              { "attribute" => "Price", "score" => "5/10", "reason" => "The Model 3 is priced higher than many affordable cars, which may deter some buyers." },
              { "attribute" => "Fuel Efficiency", "score" => "9/10", "reason" => "Exceptional efficiency as an electric vehicle, leading to low running costs." },
              { "attribute" => "Safety Ratings", "score" => "9/10", "reason" => "The Model 3 has received top safety ratings, including 5 stars from Euro NCAP." },
              { "attribute" => "Warranty and Service Plans", "score" => "7/10", "reason" => "Tesla offers a standard warranty, but service can be inconsistent depending on location." },
              { "attribute" => "Resale Value", "score" => "8/10", "reason" => "Strong demand for Tesla vehicles helps maintain high resale values." }
            ]
          },
          {
            "name" => "Tesla Model Y",
            "scores" => [
              { "attribute" => "Price", "score" => "5/10", "reason" => "Similar to the Model 3, the Model Y is priced at a premium compared to other affordable cars." },
              { "attribute" => "Fuel Efficiency", "score" => "9/10", "reason" => "Excellent efficiency as an electric SUV, providing low operating costs." },
              { "attribute" => "Safety Ratings", "score" => "9/10", "reason" => "High safety ratings, with advanced safety features and strong crash test results." },
              { "attribute" => "Warranty and Service Plans", "score" => "7/10", "reason" => "Standard warranty is offered, but service availability can vary." },
              { "attribute" => "Resale Value", "score" => "8/10", "reason" => "High demand for Tesla vehicles contributes to strong resale values." }
            ]
          },
          {
            "name" => "Volkswagen Polo",
            "scores" => [
              { "attribute" => "Price", "score" => "8/10", "reason" => "The Polo is affordably priced, making it accessible for many consumers." },
              { "attribute" => "Fuel Efficiency", "score" => "7/10", "reason" => "Offers good fuel efficiency for a gasoline vehicle, appealing to budget-conscious buyers." },
              { "attribute" => "Safety Ratings", "score" => "8/10", "reason" => "The Polo has solid safety ratings, making it a reliable choice for families." },
              { "attribute" => "Warranty and Service Plans", "score" => "7/10", "reason" => "Volkswagen provides a competitive warranty and service plan." },
              { "attribute" => "Resale Value", "score" => "7/10", "reason" => "The Polo maintains a good resale value due to its popularity and brand reputation." }
            ]
          }
        ], JSON.parse(features.competition_scores.to_json)
      end
  end

  def params(topic, query)
    begin
      report = Report.create!(query: query, owner: users(:jane))

      {
        entities: entities,
        answers: answers,
        report: report,
        topic: topic,
        language: "en"
      }
    end
  end

  def answers
    [
      {
        "question": "Which car brands offer the safest vehicles for women over 45 years old?",
        "answer": "Here are some car brands and models that are considered particularly safe for women over 45 years old, based on the latest Euro NCAP crash tests and safety ratings:\n\n### 1. **Volkswagen ID.7**\n- **Safety features**: Excellent occupant protection, advanced safety systems like lane-keeping assist and emergency braking.\n- **Reasoning**: The ID.7 has received high ratings in Euro NCAP tests and offers comprehensive safety features that are important for drivers in this age group.\n- **Source**: [ADAC](https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap/)\n\n### 2. **NIO ET5**\n- **Safety features**: Excellent occupant protection, good emergency braking system.\n- **Reasoning**: This model offers a high safety rating and is particularly suitable for tech-savvy drivers who value modern assistance systems.\n- **Source**: [AutoScout24](https://www.autoscout24.de/informieren/ratgeber/auto-sicherheit/ncap-sicherste-autos/)\n\n### 3. **Mercedes EQE**\n- **Safety features**: High safety standards, particularly in child protection, with automatic systems to prevent secondary collisions.\n- **Reasoning**: The safety features and general reliability of Mercedes make this model an excellent choice for women seeking safety and comfort.\n- **Source**: [Finn](https://www.finn.com/de-DE/auto/bestenliste/sicherstes-auto)\n\n### 4. **BMW 3 Series**\n- **Safety features**: High occupant protection (97%) and comprehensive safety features.\n- **Reasoning**: The BMW 3 Series is known for its safety standards and offers ample space, making it an ideal choice for families.\n- **Source**: [Carwow](https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos)\n\n### 5. **Toyota Yaris**\n- **Safety features**: Solid safety standards, ideal for beginner drivers.\n- **Reasoning**: The Yaris is a compact and safe vehicle, making it a good choice for women looking for a reliable and easy-to-drive car.\n- **Source**: [Finn](https://www.finn.com/de-DE/auto/bestenliste/sicherstes-auto)\n\n### Conclusion\nThe listed models are characterized by high safety ratings and modern assistance systems that are important for women over 45 years old. These vehicles not only offer protection but also comfort and user-friendliness, making them an excellent choice for this target group. When purchasing, it is important to pay attention to Euro NCAP ratings and the available safety features to make the best decision."
      },
      {
        "question": "Which car brands offer the safest vehicles for women over 45 years old?",
        "answer": "Here are some car brands and models that are considered particularly safe for women over 45 years old, based on the latest Euro NCAP test results and other safety ratings:\n\n### 1. **Volkswagen**\n   - **Model:** VW ID.7\n   - **Safety Rating:** 5 Stars (Euro NCAP)\n   - **Reasoning:** The VW ID.7 offers excellent occupant protection and is equipped with modern safety features, such as an integrated side airbag between the front seats. This makes it an excellent choice for safety and comfort.\n\n### 2. **Tesla**\n   - **Model:** Tesla Model 3\n   - **Safety Rating:** 5 Stars (Euro NCAP)\n   - **Reasoning:** The Model 3 scores highly in adult protection (96%) and child protection (86%). It is equipped with a variety of safety features that enhance driving safety.\n\n### 3. **Volvo**\n   - **Models:** Volvo XC60, Volvo S90/V90\n   - **Safety Rating:** 5 Stars (Euro NCAP)\n   - **Reasoning:** Volvo is known for its safety standards. The XC60 offers 98% occupant protection and strong safety assistance systems, while the S90/V90 models have excellent safety features.\n\n### 4. **Mercedes-Benz**\n   - **Model:** Mercedes-Benz CLA Plug-in Hybrid\n   - **Safety Rating:** 5 Stars (Euro NCAP)\n   - **Reasoning:** This model performed well in all safety categories, including very good child protection (91%). The extensive range of assistance systems increases safety.\n\n### 5. **Kia**\n   - **Model:** Kia Sorento\n   - **Safety Rating:** 5 Stars (Euro NCAP)\n   - **Reasoning:** The Sorento offers 82% adult protection and 85% child protection. It is spacious and offers a high seating position, improving visibility and comfort.\n\n### 6. **BMW**\n   - **Model:** BMW 3 Series\n   - **Safety Rating:** 5 Stars (Euro NCAP)\n   - **Reasoning:** The BMW 3 Series has outstanding safety ratings (97% for occupant protection) and is equipped with modern safety assistance systems that enhance driving safety.\n\n### 7. **Nissan**\n   - **Model:** Nissan Qashqai\n   - **Safety Rating:** 5 Stars (Euro NCAP)\n   - **Reasoning:** The Qashqai has solid safety ratings and is particularly suitable for families, as it also has good child seat ratings.\n\n### 8. **Audi**\n   - **Model:** Audi A1\n   - **Safety Rating:** 5 Stars (Euro NCAP)\n   - **Reasoning:** The Audi A1 scores highly for adult protection (95%) and child protection (85%) and offers a variety of safety features.\n\n### Conclusion\nThe selection of these models is based on their high safety ratings in Euro NCAP tests, which evaluate various aspects such as occupant protection, child safety, and the availability of safety assistance systems. These vehicles not only offer safety but also comfort and user-friendliness, making them particularly suitable for women over 45 years old.\n\n### Sources\n- [ADAC - Safe Cars According to Euro NCAP](https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap/)\n- [Carwow - Safest Cars](https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos)\n- [AutoScout24 - NCAP Safest Cars](https://www.autoscout24.de/informieren/ratgeber/auto-sicherheit/ncap-sicherste-autos/)\n- [DadsLife - Safest Family Cars](https://dadslife.at/mobilitaet/sicherste-familienautos/)"
      }
    ]
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
