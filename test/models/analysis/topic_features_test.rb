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
          "why" => "Price is a critical factor for consumers in the affordable cars category, as it directly influences purchasing decisions and market competitiveness."
        },
        {
          "name" => "Fuel Efficiency",
          "definition" => "The distance a vehicle can travel per unit of fuel, typically measured in miles per gallon (MPG).",
          "why" => "Fuel efficiency is important for budget-conscious consumers, as it affects long-term ownership costs and overall value."
        },
        {
          "name" => "Safety Ratings",
          "definition" => "Evaluations of a vehicle's safety performance, often provided by organizations like the National Highway Traffic Safety Administration (NHTSA) or the Insurance Institute for Highway Safety (IIHS).",
          "why" => "Safety ratings are crucial for consumers looking for reliable and secure vehicles, especially in the affordable segment where families may prioritize safety."
        },
        {
          "name" => "Warranty and Service Plans",
          "definition" => "The coverage provided for repairs and maintenance, including the duration and mileage limits of the warranty.",
          "why" => "A strong warranty can enhance consumer confidence and perceived value, making it an important attribute in the competitive landscape of affordable cars."
        },
        {
          "name" => "Technology Features",
          "definition" => "The inclusion of modern technology in the vehicle, such as infotainment systems, connectivity options, and driver-assistance features.",
          "why" => "Technology features can differentiate products in the affordable car market, appealing to tech-savvy consumers and enhancing the overall driving experience."
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
              {
                "attribute" => "Price",
                "score" => "7/10",
                "reason" => "The ID.7 is competitively priced within the electric vehicle segment, making it accessible for many consumers."
              },
              {
                "attribute" => "Fuel Efficiency",
                "score" => "8/10",
                "reason" => "As an electric vehicle, the ID.7 offers excellent efficiency, translating to lower running costs."
              },
              {
                "attribute" => "Safety Ratings",
                "score" => "9/10",
                "reason" => "The ID.7 has received high safety ratings, including 5 stars from Euro NCAP, making it a safe choice."
              },
              {
                "attribute" => "Warranty and Service Plans",
                "score" => "8/10",
                "reason" => "Volkswagen offers a solid warranty and service plan, enhancing consumer confidence."
              },
              {
                "attribute" => "Resale Value",
                "score" => "7/10",
                "reason" => "Electric vehicles like the ID.7 tend to have good resale value, although it can vary by market."
              }
            ]
          },
          {
            "name" => "NIO ET5",
            "scores" => [
              {
                "attribute" => "Price",
                "score" => "6/10",
                "reason" => "The ET5 is priced higher than many competitors in the affordable segment, which may limit its appeal."
              },
              {
                "attribute" => "Fuel Efficiency",
                "score" => "8/10",
                "reason" => "As an electric vehicle, it offers good efficiency, contributing to lower long-term costs."
              },
              {
                "attribute" => "Safety Ratings",
                "score" => "8/10",
                "reason" => "The ET5 has strong safety features and ratings, making it a reliable option."
              },
              {
                "attribute" => "Warranty and Service Plans",
                "score" => "7/10",
                "reason" => "NIO provides a competitive warranty, but service availability may vary by region."
              },
              {
                "attribute" => "Resale Value",
                "score" => "6/10",
                "reason" => "NIO's resale value is still developing, and it may not hold value as well as more established brands."
              }
            ]
          },
          {
            "name" => "Smart #3",
            "scores" => [
              {
                "attribute" => "Price",
                "score" => "8/10",
                "reason" => "The Smart #3 is priced affordably, appealing to budget-conscious consumers."
              },
              {
                "attribute" => "Fuel Efficiency",
                "score" => "7/10",
                "reason" => "As a compact electric vehicle, it offers decent efficiency, though not as high as larger EVs."
              },
              {
                "attribute" => "Safety Ratings",
                "score" => "7/10",
                "reason" => "Safety ratings are decent, but the vehicle lacks some advanced safety features found in competitors."
              },
              {
                "attribute" => "Warranty and Service Plans",
                "score" => "6/10",
                "reason" => "Smart offers a standard warranty, but service options may be limited in some areas."
              },
              {
                "attribute" => "Resale Value",
                "score" => "5/10",
                "reason" => "Smart vehicles generally have lower resale values compared to other brands."
              }
            ]
          },
          {
            "name" => "Tesla Model 3",
            "scores" => [
              {
                "attribute" => "Price",
                "score" => "5/10",
                "reason" => "The Model 3 is priced higher than many affordable cars, which may deter some buyers."
              },
              {
                "attribute" => "Fuel Efficiency",
                "score" => "9/10",
                "reason" => "As a leading electric vehicle, it offers exceptional efficiency and low running costs."
              },
              {
                "attribute" => "Safety Ratings",
                "score" => "9/10",
                "reason" => "The Model 3 has received top safety ratings, including 5 stars from Euro NCAP."
              },
              {
                "attribute" => "Warranty and Service Plans",
                "score" => "7/10",
                "reason" => "Tesla's warranty is competitive, but service can be inconsistent depending on location."
              },
              {
                "attribute" => "Resale Value",
                "score" => "8/10",
                "reason" => "The Model 3 tends to hold its value well, making it a good long-term investment."
              }
            ]
          },
          {
            "name" => "Tesla Model Y",
            "scores" => [
              {
                "attribute" => "Price",
                "score" => "5/10",
                "reason" => "Similar to the Model 3, the Model Y is priced higher than many affordable options."
              },
              {
                "attribute" => "Fuel Efficiency",
                "score" => "9/10",
                "reason" => "It offers excellent efficiency as an electric SUV, appealing to eco-conscious consumers."
              },
              {
                "attribute" => "Safety Ratings",
                "score" => "9/10",
                "reason" => "The Model Y has also received high safety ratings, ensuring peace of mind for buyers."
              },
              {
                "attribute" => "Warranty and Service Plans",
                "score" => "7/10",
                "reason" => "Tesla provides a solid warranty, but service availability can vary."
              },
              {
                "attribute" => "Resale Value",
                "score" => "8/10",
                "reason" => "The Model Y is expected to maintain strong resale value due to its popularity."
              }
            ]
          },
          {
            "name" => "Volkswagen Polo",
            "scores" => [
              {
                "attribute" => "Price",
                "score" => "8/10",
                "reason" => "The Polo is competitively priced, making it an attractive option for budget buyers."
              },
              {
                "attribute" => "Fuel Efficiency",
                "score" => "7/10",
                "reason" => "It offers good fuel efficiency for a gasoline vehicle, appealing to cost-conscious consumers."
              },
              {
                "attribute" => "Safety Ratings",
                "score" => "8/10",
                "reason" => "The Polo has solid safety ratings, making it a reliable choice for families."
              },
              {
                "attribute" => "Warranty and Service Plans",
                "score" => "7/10",
                "reason" => "Volkswagen offers a decent warranty and service plan, enhancing consumer confidence."
              },
              {
                "attribute" => "Resale Value",
                "score" => "7/10",
                "reason" => "The Polo generally holds its value well in the used car market."
              }
            ]
          }
        ], JSON.parse(features.competition_scores.to_json)
      end
  end

  test "End to End" do
    VCR.use_cassette("analysis/topic_features/end_to_end") do
      query = "What are the safest cars for women over 45 years old?"
      topic = { "type" => "product", "brand" => "Volkswagen", "product" => "Polo" }
      features = Analysis::TopicFeatures.new(**params(topic, query))
      features.perform_and_save
      assert_equal({
        "overarching_term" => "safest cars for women over 45",
        "term_attributes" => [
          {
            "name" => "Safety Ratings",
            "definition" => "A measure of how well a vehicle performs in crash tests and safety assessments conducted by organizations such as the National Highway Traffic Safety Administration (NHTSA) and the Insurance Institute for Highway Safety (IIHS).",
            "why" => "Safety ratings are crucial as they provide a standardized assessment of a vehicle's crashworthiness and safety features, which is particularly important for women over 45 who may prioritize safety in their vehicle choice."
          },
          {
            "name" => "Comfort and Ergonomics",
            "definition" => "The design and layout of the vehicle's interior, including seat comfort, driving position, and ease of access, tailored to the needs of the driver and passengers.",
            "why" => "Comfort and ergonomics are essential for older drivers, as they can affect driving posture, fatigue levels, and overall driving experience, making it a key attribute for this demographic."
          },
          {
            "name" => "Advanced Safety Features",
            "definition" => "Technological enhancements in vehicles that assist in preventing accidents, such as automatic emergency braking, lane departure warning, and blind-spot monitoring.",
            "why" => "Advanced safety features are increasingly important for enhancing driver awareness and reducing the risk of accidents, which is particularly relevant for women over 45 who may seek additional support while driving."
          },
          {
            "name" => "Reliability and Maintenance Costs",
            "definition" => "The likelihood of a vehicle to perform well over time without frequent repairs, along with the associated costs of maintenance and repairs.",
            "why" => "Reliability and low maintenance costs are significant for older drivers who may prefer vehicles that require less frequent servicing and are dependable over the long term."
          },
          {
            "name" => "Insurance Costs",
            "definition" => "The average cost of insuring a vehicle, which can vary based on the car's safety features, repair costs, and theft rates.",
            "why" => "Insurance costs are an important consideration for women over 45, as they can impact the overall affordability of owning a vehicle, making it a critical factor in their purchasing decision."
          }
        ],
        "competition_scores" => [
          {
            "name" => "Volkswagen VW ID.7",
            "scores" => [
              {
                "attribute" => "Safety Ratings",
                "score" => "10/10",
                "reason" => "The VW ID.7 has received high ratings in Euro NCAP tests, indicating excellent occupant protection and advanced safety systems."
              },
              {
                "attribute" => "Comfort and Ergonomics",
                "score" => "9/10",
                "reason" => "The ID.7 features a spacious interior with comfortable seating and an intuitive layout, enhancing the driving experience."
              },
              {
                "attribute" => "Advanced Safety Features",
                "score" => "10/10",
                "reason" => "Equipped with modern safety features like lane-keeping assist and emergency braking, it provides comprehensive support for drivers."
              },
              {
                "attribute" => "Reliability and Maintenance Costs",
                "score" => "8/10",
                "reason" => "Volkswagen vehicles are generally reliable, though maintenance costs can vary depending on the model."
              },
              {
                "attribute" => "Insurance Costs",
                "score" => "7/10",
                "reason" => "Insurance costs are moderate, influenced by the vehicle's safety features and repair costs."
              }
            ]
          },
          {
            "name" => "NIO ET5",
            "scores" => [
              {
                "attribute" => "Safety Ratings",
                "score" => "9/10",
                "reason" => "The NIO ET5 has received high safety ratings, particularly for occupant protection."
              },
              {
                "attribute" => "Comfort and Ergonomics",
                "score" => "8/10",
                "reason" => "The interior is designed for comfort, though it may not be as spacious as some competitors."
              },
              {
                "attribute" => "Advanced Safety Features",
                "score" => "9/10",
                "reason" => "It includes a good range of modern safety features, appealing to tech-savvy drivers."
              },
              {
                "attribute" => "Reliability and Maintenance Costs",
                "score" => "7/10",
                "reason" => "As a newer brand, long-term reliability is still being established, but initial reports are positive."
              },
              {
                "attribute" => "Insurance Costs",
                "score" => "6/10",
                "reason" => "Insurance costs may be higher due to the vehicle's advanced technology and repair costs."
              }
            ]
          },
          {
            "name" => "Smart #3",
            "scores" => [
              {
                "attribute" => "Safety Ratings",
                "score" => "7/10",
                "reason" => "The Smart #3 has decent safety ratings but lacks the comprehensive features of larger vehicles."
              },
              {
                "attribute" => "Comfort and Ergonomics",
                "score" => "6/10",
                "reason" => "The compact design may limit comfort for taller drivers or passengers."
              },
              {
                "attribute" => "Advanced Safety Features",
                "score" => "6/10",
                "reason" => "It offers basic safety features but lacks some advanced systems found in larger models."
              },
              {
                "attribute" => "Reliability and Maintenance Costs",
                "score" => "8/10",
                "reason" => "Smart vehicles are generally reliable with low maintenance costs."
              },
              {
                "attribute" => "Insurance Costs",
                "score" => "8/10",
                "reason" => "Insurance costs are typically lower for smaller vehicles like the Smart #3."
              }
            ]
          },
          {
            "name" => "Tesla Model 3",
            "scores" => [
              {
                "attribute" => "Safety Ratings",
                "score" => "10/10",
                "reason" => "The Tesla Model 3 has received top ratings in safety tests, particularly for adult and child protection."
              },
              {
                "attribute" => "Comfort and Ergonomics",
                "score" => "8/10",
                "reason" => "The interior is modern and comfortable, though some may find the seating position less traditional."
              },
              {
                "attribute" => "Advanced Safety Features",
                "score" => "10/10",
                "reason" => "It is equipped with a comprehensive suite of advanced safety features, enhancing overall safety."
              },
              {
                "attribute" => "Reliability and Maintenance Costs",
                "score" => "7/10",
                "reason" => "Tesla vehicles have variable reliability, but maintenance costs are generally lower due to fewer moving parts."
              },
              {
                "attribute" => "Insurance Costs",
                "score" => "7/10",
                "reason" => "Insurance costs can be higher due to the vehicle's value and repair costs."
              }
            ]
          },
          {
            "name" => "Tesla Model Y",
            "scores" => [
              {
                "attribute" => "Safety Ratings",
                "score" => "10/10",
                "reason" => "The Model Y has excellent safety ratings, similar to the Model 3, with strong occupant protection."
              },
              {
                "attribute" => "Comfort and Ergonomics",
                "score" => "9/10",
                "reason" => "The spacious interior and high seating position enhance comfort for all passengers."
              },
              {
                "attribute" => "Advanced Safety Features",
                "score" => "10/10",
                "reason" => "It includes a full range of advanced safety features, making it very safe to drive."
              },
              {
                "attribute" => "Reliability and Maintenance Costs",
                "score" => "7/10",
                "reason" => "Similar to the Model 3, it has variable reliability but lower maintenance costs."
              },
              {
                "attribute" => "Insurance Costs",
                "score" => "7/10",
                "reason" => "Insurance costs are generally higher due to the vehicle's value."
              }
            ]
          },
          {
            "name" => "Volkswagen Polo",
            "scores" => [
              {
                "attribute" => "Safety Ratings",
                "score" => "8/10",
                "reason" => "The Polo has good safety ratings but is not as high as larger models."
              },
              {
                "attribute" => "Comfort and Ergonomics",
                "score" => "7/10",
                "reason" => "The interior is comfortable for a compact car, but space is limited."
              },
              {
                "attribute" => "Advanced Safety Features",
                "score" => "7/10",
                "reason" => "It offers a decent range of safety features but lacks some advanced options."
              },
              {
                "attribute" => "Reliability and Maintenance Costs",
                "score" => "8/10",
                "reason" => "Volkswagen vehicles are generally reliable with reasonable maintenance costs."
              },
              {
                "attribute" => "Insurance Costs",
                "score" => "8/10",
                "reason" => "Insurance costs are typically lower for compact vehicles like the Polo."
              }
            ]
          }
        ]
      }, features.reload.result)
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
