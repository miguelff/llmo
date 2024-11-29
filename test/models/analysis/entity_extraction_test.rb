require "test_helper"

class Analysis::EntityExtractorTest < ActiveSupport::TestCase
  setup do
    @report = Report.create!(query: "best cars for women over 45", brand_info: "Volkswagen Tiguan", owner: users(:jane))
  end

  test "first pass" do
    answers = [
      {
        "question" => "Which car models offer the best safety features for families with children?",
        "answer"   =>  <<-TEXT.squish
         Based on the information from various sources, here are some of the safest car brands and models for families with children in 2023:

        1. **Kia Telluride**
            - **Why Chosen**: The Kia Telluride is recognized for its spacious interior, seating for 7 or 8 passengers, and a smooth ride. It is equipped with essential safety features such as forward automatic emergency braking and lane-keep assist. It also includes family-friendly features like multiple USB ports and rear-seat comforts.
            - **Source**: [U.S. News Best Cars for Families 2023](https://cars.usnews.com/cars-trucks/best-cars-for-families-2023)

        2. **Toyota Camry Hybrid**
            - **Why Chosen**: The Toyota Camry Hybrid stands out for its excellent fuel economy, reliability, and safety features. It offers generous interior space and a smooth ride, making it ideal for family use. It also includes advanced safety technologies and a high ease-of-use rating for car-seat installation.
            - **Source**: [U.S. News Best Cars for Families 2023](https://cars.usnews.com/cars-trucks/best-cars-for-families-2023)

        3. **Honda Odyssey**
            - **Why Chosen**: The Honda Odyssey is highly rated as a minivan, perfect for family transportation. It features a comfortable ride, substantial storage capacity, and essential safety features like forward automatic emergency braking and lane-keep assist.
            - **Source**: [Consumer Reports Safest New Cars 2023](https://www.consumerreports.org/cars/car-safety/the-safest-new-cars-of-2023-according-to-iihs-a8504542560/)

        4. **Toyota Highlander Hybrid**
            - **Why Chosen**: This model offers a three-row seating configuration and a fuel-efficient hybrid powertrain. It is equipped with modern tech features and driver assistance technologies, making it a safe and reliable choice for families.
            - **Source**: [Consumer Reports Safest New Cars 2023](https://www.consumerreports.org/cars/car-safety/the-safest-new-cars-of-2023-according-to-iihs-a8504542560/)

        5. **Hyundai Tucson**
            - **Why Chosen**: The Hyundai Tucson is a compact family SUV known for comfort, convenience, and a spacious cabin. It includes appealing tech features and efficient performance, along with comprehensive safety equipment.
            - **Source**: [Euro NCAP Safest Family Cars](https://www.euroncap.com/en/ratings-rewards/safest-family-cars/)

        These models are chosen based on their high safety ratings, reliability, and family-friendly features. They have been recognized by reputable sources for their comprehensive safety technologies, making them suitable choices for families with children.
      TEXT
    }
    ]
    VCR.use_cassette("analysis/entity_extractor/first_pass") do
      extractor = Analysis::EntityExtractor.new(answers: answers, language: "eng", report: @report)
      assert_equal(
        { "brands"=>[], "products"=>[ { "name"=>"Kia Telluride", "links"=>[ "https://cars.usnews.com/cars-trucks/best-cars-for-families-2023" ], "positions"=>[ 1 ] }, { "name"=>"Toyota Camry Hybrid", "links"=>[ "https://cars.usnews.com/cars-trucks/best-cars-for-families-2023" ], "positions"=>[ 2 ] }, { "name"=>"Honda Odyssey", "links"=>[ "https://www.consumerreports.org/cars/car-safety/the-safest-new-cars-of-2023-according-to-iihs-a8504542560/" ], "positions"=>[ 3 ] }, { "name"=>"Toyota Highlander Hybrid", "links"=>[ "https://www.consumerreports.org/cars/car-safety/the-safest-new-cars-of-2023-according-to-iihs-a8504542560/" ], "positions"=>[ 4 ] }, { "name"=>"Hyundai Tucson", "links"=>[ "https://www.euroncap.com/en/ratings-rewards/safest-family-cars/" ], "positions"=>[ 5 ] } ], "links"=>{ "https://cars.usnews.com/cars-trucks/best-cars-for-families-2023"=>{ "product_hits"=>2, "brand_hits"=>0, "orphan_hits"=>1, "brands"=>[], "products"=>[ "Kia Telluride", "Toyota Camry Hybrid" ] }, "https://www.consumerreports.org/cars/car-safety/the-safest-new-cars-of-2023-according-to-iihs-a8504542560/"=>{ "product_hits"=>2, "brand_hits"=>0, "orphan_hits"=>1, "brands"=>[], "products"=>[ "Honda Odyssey", "Toyota Highlander Hybrid" ] }, "https://www.euroncap.com/en/ratings-rewards/safest-family-cars/"=>{ "product_hits"=>1, "brand_hits"=>0, "orphan_hits"=>1, "brands"=>[], "products"=>[ "Hyundai Tucson" ] } } },
        JSON.parse(extractor.first_pass.to_json)
      )
    end
  end

  test "second pass" do
    VCR.use_cassette("analysis/entity_extractor/second_pass") do
      extractor = Analysis::EntityExtractor.new(answers: [ "This variable doesn't matter for this test" ], language: "eng", report: @report)
      first_pass_result = { "brands"=>[ { "name"=>"Kia" } ], "products"=>[ { "name"=>"Kia Telluride", "links"=>[ "https://cars.usnews.com/cars-trucks/best-cars-for-families-2023" ], "positions"=>[ 1 ] }, { "name"=>"Toyota Camry Hybrid", "links"=>[ "https://cars.usnews.com/cars-trucks/best-cars-for-families-2023" ], "positions"=>[ 2 ] }, { "name"=>"Honda Odyssey", "links"=>[ "https://www.consumerreports.org/cars/car-safety/the-safest-new-cars-of-2023-according-to-iihs-a8504542560/" ], "positions"=>[ 3 ] }, { "name"=>"Toyota Highlander Hybrid", "links"=>[ "https://www.consumerreports.org/cars/car-safety/the-safest-new-cars-of-2023-according-to-iihs-a8504542560/" ], "positions"=>[ 4 ] }, { "name"=>"Hyundai Tucson", "links"=>[ "https://www.euroncap.com/en/ratings-rewards/safest-family-cars/" ], "positions"=>[ 5 ] } ], "links"=>{ "https://cars.usnews.com/cars-trucks/best-cars-for-families-2023"=>{ "product_hits"=>2, "brand_hits"=>0, "orphan_hits"=>1, "brands"=>[], "products"=>[ "Kia Telluride", "Toyota Camry Hybrid" ] }, "https://www.consumerreports.org/cars/car-safety/the-safest-new-cars-of-2023-according-to-iihs-a8504542560/"=>{ "product_hits"=>2, "brand_hits"=>0, "orphan_hits"=>1, "brands"=>[], "products"=>[ "Honda Odyssey", "Toyota Highlander Hybrid" ] }, "https://www.euroncap.com/en/ratings-rewards/safest-family-cars/"=>{ "product_hits"=>1, "brand_hits"=>0, "orphan_hits"=>1, "brands"=>[], "products"=>[ "Hyundai Tucson" ] } } }
      assert_equal(
        { "brands"=>[ { "type"=>"brand", "name"=>"Kia", "products"=>[ { "name"=>"Kia Telluride" } ] }, { "type"=>"brand", "name"=>"Toyota", "products"=>[ { "name"=>"Toyota Camry Hybrid" }, { "name"=>"Toyota Highlander Hybrid" } ] }, { "type"=>"brand", "name"=>"Honda", "products"=>[ { "name"=>"Honda Odyssey" } ] }, { "type"=>"brand", "name"=>"Hyundai", "products"=>[ { "name"=>"Hyundai Tucson" } ] } ] },
        JSON.parse(extractor.second_pass(first_pass_result).to_json)
      )
    end
  end

  test "perform" do
      answers = [
      {
        "question" => "Which car models offer the best safety features for families with children?",
        "answer"   =>  <<-TEXT.squish
         Based on the information from various sources, here are some of the safest car brands and models for families with children in 2023:

        1. **Kia Telluride**
            - **Why Chosen**: The Kia Telluride is recognized for its spacious interior, seating for 7 or 8 passengers, and a smooth ride. It is equipped with essential safety features such as forward automatic emergency braking and lane-keep assist. It also includes family-friendly features like multiple USB ports and rear-seat comforts.
            - **Source**: [U.S. News Best Cars for Families 2023](https://cars.usnews.com/cars-trucks/best-cars-for-families-2023)

        2. **Toyota Camry Hybrid**
            - **Why Chosen**: The Toyota Camry Hybrid stands out for its excellent fuel economy, reliability, and safety features. It offers generous interior space and a smooth ride, making it ideal for family use. It also includes advanced safety technologies and a high ease-of-use rating for car-seat installation.
            - **Source**: [U.S. News Best Cars for Families 2023](https://cars.usnews.com/cars-trucks/best-cars-for-families-2023)

        3. **Honda Odyssey**
            - **Why Chosen**: The Honda Odyssey is highly rated as a minivan, perfect for family transportation. It features a comfortable ride, substantial storage capacity, and essential safety features like forward automatic emergency braking and lane-keep assist.
            - **Source**: [Consumer Reports Safest New Cars 2023](https://www.consumerreports.org/cars/car-safety/the-safest-new-cars-of-2023-according-to-iihs-a8504542560/)

        4. **Toyota Highlander Hybrid**
            - **Why Chosen**: This model offers a three-row seating configuration and a fuel-efficient hybrid powertrain. It is equipped with modern tech features and driver assistance technologies, making it a safe and reliable choice for families.
            - **Source**: [Consumer Reports Safest New Cars 2023](https://www.consumerreports.org/cars/car-safety/the-safest-new-cars-of-2023-according-to-iihs-a8504542560/)

        5. **Hyundai Tucson**
            - **Why Chosen**: The Hyundai Tucson is a compact family SUV known for comfort, convenience, and a spacious cabin. It includes appealing tech features and efficient performance, along with comprehensive safety equipment.
            - **Source**: [Euro NCAP Safest Family Cars](https://www.euroncap.com/en/ratings-rewards/safest-family-cars/)

        These models are chosen based on their high safety ratings, reliability, and family-friendly features. They have been recognized by reputable sources for their comprehensive safety technologies, making them suitable choices for families with children.
      TEXT
    }
    ]
    VCR.use_cassette("analysis/entity_extractor/perform") do
      extraction = Analysis::EntityExtractor.new(answers: answers, language: "eng", report: @report)
      assert extraction.perform_and_save
      assert_equal(
        { "brands"=>[ { "name"=>"Kia", "products"=>[ "Kia Telluride" ], "links"=>[ "https://cars.usnews.com/cars-trucks/best-cars-for-families-2023" ], "positions"=>[ 1 ] }, { "name"=>"Toyota", "products"=>[ "Toyota Camry Hybrid", "Toyota Highlander Hybrid" ], "links"=>[ "https://cars.usnews.com/cars-trucks/best-cars-for-families-2023", "https://www.consumerreports.org/cars/car-safety/the-safest-new-cars-of-2023-according-to-iihs-a8504542560/" ], "positions"=>[ 2, 4 ] }, { "name"=>"Honda", "products"=>[ "Honda Odyssey" ], "links"=>[ "https://www.consumerreports.org/cars/car-safety/the-safest-new-cars-of-2023-according-to-iihs-a8504542560/" ], "positions"=>[ 3 ] }, { "name"=>"Hyundai", "products"=>[ "Hyundai Tucson" ], "links"=>[ "https://www.euroncap.com/en/ratings-rewards/safest-family-cars/" ], "positions"=>[ 5 ] } ], "products"=>[ { "name"=>"Kia Telluride", "links"=>[ "https://cars.usnews.com/cars-trucks/best-cars-for-families-2023" ], "positions"=>[ 1 ], "brand"=>"Kia" }, { "name"=>"Toyota Camry Hybrid", "links"=>[ "https://cars.usnews.com/cars-trucks/best-cars-for-families-2023" ], "positions"=>[ 2 ], "brand"=>"Toyota" }, { "name"=>"Honda Odyssey", "links"=>[ "https://www.consumerreports.org/cars/car-safety/the-safest-new-cars-of-2023-according-to-iihs-a8504542560/" ], "positions"=>[ 3 ], "brand"=>"Honda" }, { "name"=>"Toyota Highlander Hybrid", "links"=>[ "https://www.consumerreports.org/cars/car-safety/the-safest-new-cars-of-2023-according-to-iihs-a8504542560/" ], "positions"=>[ 4 ], "brand"=>"Toyota" }, { "name"=>"Hyundai Tucson", "links"=>[ "https://www.euroncap.com/en/ratings-rewards/safest-family-cars/" ], "positions"=>[ 5 ], "brand"=>"Hyundai" } ], "links"=>[ [ "https://cars.usnews.com/cars-trucks/best-cars-for-families-2023", { "orphan_hits"=>1, "brands"=>[ "Kia", "Toyota" ], "products"=>[ "Kia Telluride", "Toyota Camry Hybrid" ] } ], [ "https://www.consumerreports.org/cars/car-safety/the-safest-new-cars-of-2023-according-to-iihs-a8504542560/", { "orphan_hits"=>1, "brands"=>[ "Honda", "Toyota" ], "products"=>[ "Honda Odyssey", "Toyota Highlander Hybrid" ] } ], [ "https://www.euroncap.com/en/ratings-rewards/safest-family-cars/", { "orphan_hits"=>1, "brands"=>[ "Hyundai" ], "products"=>[ "Hyundai Tucson" ] } ] ] },
        extraction.reload.result
      )
    end
  end
end
