require "test_helper"

class Analysis::CompetitorsTest < ActiveSupport::TestCase
  test "OverarchingTerm: when topic is a product" do
    VCR.use_cassette("analysis/competitors/overarching_term/product") do
      query = "What are the best electric cars in the market?"
      topic = { "type" => "product", "brand" => "Tesla", "product" => "Model 3" }
      features = Analysis::Competitors.new(**params(topic, query))
      assert_equal "electric cars", features.overarching_term
    end
  end

  test "OverarchingTerm: when topic is a brand" do
    VCR.use_cassette("analysis/competitors/overarching_term/brand") do
      query = "What are the best electric cars in the market?"
      topic = { "type" => "brand", "brand" => "Volkswagen" }
      features = Analysis::Competitors.new(**params(topic, query))
      assert_equal "electric cars", features.overarching_term
    end
  end

  test "OverarchingTerm: when topic is a brand, but the query doesn't seem to be about brands" do
    VCR.use_cassette("analysis/competitors/overarching_term/brand_and_query") do
      query = "What is the most affordable car you can buy if you are a retired woman with grand children?"
      topic = { "type" => "brand", "brand" => "Volkswagen" }
      features = Analysis::Competitors.new(**params(topic, query))
      assert_equal "affordable family cars", features.overarching_term
    end
  end

  test "TermAttributes" do
    VCR.use_cassette("analysis/competitors/term_attributes") do
      query = "What are the most affordable cars in the market?"
      # Inferred by a previous step of the pipeline (from "Volkswagen Polo" entered into the brand_info input field)
      topic = { "type" => "product", "brand" => "Volkswagen", "product" => "Polo" }
      features = Analysis::Competitors.new(**params(topic, query))
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
          "name" => "Technology and Features",
          "definition" => "The availability of modern technology and features, such as infotainment systems, connectivity options, and driver-assistance technologies.",
          "why" => "Consumers in the affordable car market often seek vehicles that offer good value in terms of technology and features, which can differentiate competitors in a crowded market."
        }
      ]
      assert_equal expected_attributes, JSON.parse(features.term_attributes.to_json)
    end
  end

  test "CompetitionScores" do
      VCR.use_cassette("analysis/competitors/competition_scores") do
        query = "What are the most affordable cars in the market?"
        topic = { "type" => "product", "brand" => "Volkswagen", "product" => "Polo" }
        features = Analysis::Competitors.new(**params(topic, query))
        assert_equal(
          [
            {
              "name" => "Volkswagen VW ID.7",
              "scores" => [
                { "attribute" => "Price", "score" => "6/10", "reason" => "The ID.7 is priced higher than some traditional affordable cars, making it less accessible for budget-conscious buyers." },
                { "attribute" => "Fuel Efficiency", "score" => "8/10", "reason" => "The ID.7 offers good electric range and efficiency, appealing to those looking for lower running costs." },
                { "attribute" => "Safety Ratings", "score" => "9/10", "reason" => "It has received high safety ratings, particularly in occupant protection, making it a strong choice for safety-conscious consumers." },
                { "attribute" => "Warranty and Service Plans", "score" => "7/10", "reason" => "Volkswagen offers a competitive warranty, but it may not be as extensive as some competitors." },
                { "attribute" => "Resale Value", "score" => "7/10", "reason" => "The resale value is decent, but electric vehicles can fluctuate based on market trends." }
              ]
            },
            {
              "name" => "NIO ET5",
              "scores" => [
                { "attribute" => "Price", "score" => "5/10", "reason" => "The ET5 is positioned as a premium electric vehicle, which may be out of reach for many budget buyers." },
                { "attribute" => "Fuel Efficiency", "score" => "8/10", "reason" => "As an electric vehicle, it offers excellent efficiency and lower running costs." },
                { "attribute" => "Safety Ratings", "score" => "8/10", "reason" => "The ET5 has good safety features and ratings, appealing to safety-focused consumers." },
                { "attribute" => "Warranty and Service Plans", "score" => "6/10", "reason" => "NIO offers a warranty, but service availability may be limited outside of major markets." },
                { "attribute" => "Resale Value", "score" => "6/10", "reason" => "Resale value is uncertain due to the brand's newer presence in the market." }
              ]
            },
            {
              "name" => "Smart #3",
              "scores" => [
                { "attribute" => "Price", "score" => "7/10", "reason" => "The Smart #3 is relatively affordable compared to other electric vehicles, making it accessible." },
                { "attribute" => "Fuel Efficiency", "score" => "7/10", "reason" => "It offers decent efficiency for city driving, but may not be as competitive for long distances." },
                { "attribute" => "Safety Ratings", "score" => "7/10", "reason" => "Safety ratings are average, with basic features that meet standard requirements." },
                { "attribute" => "Warranty and Service Plans", "score" => "7/10", "reason" => "Smart provides a reasonable warranty, which adds to consumer confidence." },
                { "attribute" => "Resale Value", "score" => "5/10", "reason" => "Resale value can be low due to the niche market for Smart vehicles." }
              ]
            },
            {
              "name" => "Tesla Model 3",
              "scores" => [
                { "attribute" => "Price", "score" => "5/10", "reason" => "The Model 3 is priced higher than many traditional affordable cars, which may deter some buyers." },
                { "attribute" => "Fuel Efficiency", "score" => "9/10", "reason" => "It has excellent electric range and efficiency, making it cost-effective in the long run." },
                { "attribute" => "Safety Ratings", "score" => "9/10", "reason" => "The Model 3 has top safety ratings and advanced safety features, appealing to safety-conscious buyers." },
                { "attribute" => "Warranty and Service Plans", "score" => "6/10", "reason" => "Tesla's warranty is standard, but service can be challenging in some areas." },
                { "attribute" => "Resale Value", "score" => "8/10", "reason" => "The Model 3 tends to hold its value well due to high demand." }
              ]
            },
            {
              "name" => "Tesla Model Y",
              "scores" => [
                { "attribute" => "Price", "score" => "4/10", "reason" => "The Model Y is more expensive than many affordable options, which may limit its market." },
                { "attribute" => "Fuel Efficiency", "score" => "9/10", "reason" => "It offers excellent efficiency and range, making it a cost-effective choice for electric vehicle owners." },
                { "attribute" => "Safety Ratings", "score" => "9/10", "reason" => "The Model Y has high safety ratings and advanced features, making it a strong contender for safety." },
                { "attribute" => "Warranty and Service Plans", "score" => "6/10", "reason" => "Similar to the Model 3, the warranty is standard but service can be inconsistent." },
                { "attribute" => "Resale Value", "score" => "8/10", "reason" => "The Model Y retains value well, benefiting from strong demand." }
              ]
            },
            {
              "name" => "Volkswagen Polo",
              "scores" => [
                { "attribute" => "Price", "score" => "8/10", "reason" => "The Polo is competitively priced, making it a strong option in the affordable car segment." },
                { "attribute" => "Fuel Efficiency", "score" => "7/10", "reason" => "It offers decent fuel efficiency, appealing to budget-conscious consumers." },
                { "attribute" => "Safety Ratings", "score" => "8/10", "reason" => "The Polo has good safety ratings and features, making it a reliable choice." },
                { "attribute" => "Warranty and Service Plans", "score" => "7/10", "reason" => "Volkswagen provides a solid warranty, which adds to consumer confidence." },
                { "attribute" => "Resale Value", "score" => "7/10", "reason" => "The Polo generally holds its value well in the used car market." }
              ]
            }
          ],
          JSON.parse(features.competition_scores.to_json)
        )
      end
  end

  test "End to End" do
    VCR.use_cassette("analysis/competitors/end_to_end") do
      query = "What are the safest cars for women over 45 years old?"
      topic = { "type" => "product", "brand" => "Volkswagen", "product" => "Polo" }
      features = Analysis::Competitors.new(**params(topic, query))
      features.perform_and_save
      assert_equal({ "overarching_term"=>"safe cars for women", "term_attributes"=>[ { "name"=>"Safety Ratings", "definition"=>"A measure of how well a vehicle performs in crash tests and safety assessments conducted by organizations such as the National Highway Traffic Safety Administration (NHTSA) or the Insurance Institute for Highway Safety (IIHS).", "why"=>"Safety ratings are crucial as they provide a quantifiable assessment of a vehicle's ability to protect its occupants in the event of an accident, which is a primary concern for women when choosing a safe car." }, { "name"=>"Reliability", "definition"=>"The likelihood that a vehicle will perform without failure over a specified period or distance, often assessed through consumer reports and warranty claims.", "why"=>"Reliability is important because women often seek vehicles that require less maintenance and are dependable for daily use, ensuring peace of mind." }, { "name"=>"User-Friendly Technology", "definition"=>"The ease of use and accessibility of in-car technology features such as navigation, infotainment systems, and safety assist technologies.", "why"=>"User-friendly technology enhances the driving experience and ensures that drivers can focus on the road, which is particularly important for women who may prioritize intuitive controls." }, { "name"=>"Comfort and Space", "definition"=>"The amount of interior space available for passengers and cargo, as well as the overall comfort of the seating and ride quality.", "why"=>"Comfort and space are significant for women who may prioritize family needs, such as transporting children or carrying groceries, making it essential to evaluate how well a car accommodates these requirements." }, { "name"=>"Fuel Efficiency", "definition"=>"The distance a vehicle can travel per unit of fuel, typically measured in miles per gallon (MPG).", "why"=>"Fuel efficiency is a key consideration for many consumers, including women, as it impacts the overall cost of ownership and environmental considerations, making it an important attribute to assess." } ], "competition_scores"=>[ { "name"=>"Volkswagen VW ID.7", "scores"=>[ { "attribute"=>"Safety Ratings", "score"=>"10/10", "reason"=>"The VW ID.7 has received high ratings in Euro NCAP tests, demonstrating excellent occupant protection and advanced safety features." }, { "attribute"=>"Reliability", "score"=>"8/10", "reason"=>"Volkswagen vehicles are generally known for their reliability, and the ID.7 is expected to follow this trend with good warranty coverage." }, { "attribute"=>"User-Friendly Technology", "score"=>"9/10", "reason"=>"The ID.7 features intuitive controls and modern infotainment systems that enhance the driving experience." }, { "attribute"=>"Comfort and Space", "score"=>"9/10", "reason"=>"The ID.7 offers ample interior space and comfort, making it suitable for families." }, { "attribute"=>"Fuel Efficiency", "score"=>"8/10", "reason"=>"As an electric vehicle, the ID.7 has excellent fuel efficiency in terms of energy consumption." } ] }, { "name"=>"NIO ET5", "scores"=>[ { "attribute"=>"Safety Ratings", "score"=>"9/10", "reason"=>"The NIO ET5 has received high safety ratings and offers excellent occupant protection." }, { "attribute"=>"Reliability", "score"=>"7/10", "reason"=>"NIO is a newer brand, and while it has shown promise, long-term reliability is still being established." }, { "attribute"=>"User-Friendly Technology", "score"=>"9/10", "reason"=>"The ET5 is equipped with advanced technology and user-friendly interfaces." }, { "attribute"=>"Comfort and Space", "score"=>"8/10", "reason"=>"The ET5 provides good comfort and space for passengers." }, { "attribute"=>"Fuel Efficiency", "score"=>"8/10", "reason"=>"As an electric vehicle, it offers good efficiency, though real-world performance may vary." } ] }, { "name"=>"Smart #3", "scores"=>[ { "attribute"=>"Safety Ratings", "score"=>"7/10", "reason"=>"The Smart #3 has decent safety features but may not perform as well in crash tests compared to larger vehicles." }, { "attribute"=>"Reliability", "score"=>"6/10", "reason"=>"Smart vehicles have mixed reliability ratings, and the #3 is still new to the market." }, { "attribute"=>"User-Friendly Technology", "score"=>"8/10", "reason"=>"The Smart #3 is designed with user-friendly technology, though it may lack some advanced features." }, { "attribute"=>"Comfort and Space", "score"=>"7/10", "reason"=>"As a compact vehicle, it offers limited space but is comfortable for city driving." }, { "attribute"=>"Fuel Efficiency", "score"=>"9/10", "reason"=>"The Smart #3, being electric, offers excellent fuel efficiency." } ] }, { "name"=>"Tesla Model 3", "scores"=>[ { "attribute"=>"Safety Ratings", "score"=>"10/10", "reason"=>"The Model 3 has received top safety ratings, excelling in occupant protection and advanced safety features." }, { "attribute"=>"Reliability", "score"=>"8/10", "reason"=>"Tesla has a good reputation for reliability, though some issues have been reported." }, { "attribute"=>"User-Friendly Technology", "score"=>"10/10", "reason"=>"The Model 3 features highly intuitive technology and a user-friendly interface." }, { "attribute"=>"Comfort and Space", "score"=>"8/10", "reason"=>"The Model 3 offers good comfort and space for passengers, though rear space may be limited." }, { "attribute"=>"Fuel Efficiency", "score"=>"9/10", "reason"=>"As an electric vehicle, it has excellent energy efficiency." } ] }, { "name"=>"Tesla Model Y", "scores"=>[ { "attribute"=>"Safety Ratings", "score"=>"10/10", "reason"=>"The Model Y shares the same safety features as the Model 3 and has received high safety ratings." }, { "attribute"=>"Reliability", "score"=>"8/10", "reason"=>"Similar to the Model 3, the Model Y has a good reliability reputation." }, { "attribute"=>"User-Friendly Technology", "score"=>"10/10", "reason"=>"The Model Y offers advanced technology and a very user-friendly interface." }, { "attribute"=>"Comfort and Space", "score"=>"9/10", "reason"=>"The Model Y provides more space than the Model 3, making it suitable for families." }, { "attribute"=>"Fuel Efficiency", "score"=>"9/10", "reason"=>"As an electric vehicle, it offers excellent energy efficiency." } ] }, { "name"=>"Volkswagen Polo", "scores"=>[ { "attribute"=>"Safety Ratings", "score"=>"8/10", "reason"=>"The Polo has decent safety ratings but does not match the higher-end models." }, { "attribute"=>"Reliability", "score"=>"8/10", "reason"=>"Volkswagen is known for reliability, and the Polo is a well-regarded model." }, { "attribute"=>"User-Friendly Technology", "score"=>"7/10", "reason"=>"The Polo has user-friendly technology, though it may not be as advanced as newer models." }, { "attribute"=>"Comfort and Space", "score"=>"7/10", "reason"=>"The Polo is compact, offering limited space but decent comfort for city driving." }, { "attribute"=>"Fuel Efficiency", "score"=>"8/10", "reason"=>"The Polo is fuel-efficient, especially in its petrol variants." } ] } ] }, features.reload.result)
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
