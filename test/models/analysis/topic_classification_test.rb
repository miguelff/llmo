require "test_helper"

class Analysis::TopicClassificationTest < ActiveSupport::TestCase
    test "topic classification" do
      VCR.use_cassette("analysis/topic_classification") do
        expectations = {
          "Samsung"                         => { "type" => "brand",   "brand" => "Samsung" },
          "Nike"                            => { "type" => "brand",   "brand" => "Nike" },
          "Tesla"                           => { "type" => "brand",   "brand" => "Tesla" },
          "Gucci"                           => { "type" => "brand",   "brand" => "Gucci" },
          "Microsoft"                       => { "type" => "brand",   "brand" => "Microsoft" },
          "Tesla Model 3"                   => { "type" => "product", "brand" => "Tesla", "product" => "Model 3" },
          "iPhone 15 Pro Max"               => { "type" => "product", "brand" => "Apple", "product" => "iPhone 15 Pro Max" },
          "Sony WH-1000XM5"                 => { "type" => "product", "brand" => "Sony", "product" => "WH-1000XM5" },
          "LG B4 OLED TV"                   => { "type" => "product", "brand" => "LG", "product" => "B4 OLED TV" },
          "Adidas Ultraboost 22"            => { "type" => "product", "brand" => "Adidas", "product" => "Ultraboost 22" },
          "Volvo XC40"                      => { "type" => "product", "brand" => "Volvo", "product" => "XC40" },
          "Dell XPS 13"                     => { "type" => "product", "brand" => "Dell", "product" => "XPS 13" },
          "Canon EOS R5"                    => { "type" => "product", "brand" => "Canon", "product" => "EOS R5" },
          "Bose QuietComfort 45"            => { "type" => "product", "brand" => "Bose", "product" => "QuietComfort 45" },
          "MacBook Air M2"                  => { "type" => "product", "brand" => "Apple", "product" => "MacBook Air M2" },
          "Netflix"                         => { "type" => "service", "brand" => "Netflix" },
          "Spotify Premium"                 => { "type" => "service", "brand" => "Spotify", "product" => "Premium" },
          "Amazon Web Services"             => { "type" => "service", "brand" => "Amazon", "product" => "Web Services" },
          "Uber Eats"                       => { "type" => "service", "brand" => "Uber", "product" => "Eats" },
          "Adobe Creative Cloud"            => { "type" => "service", "brand" => "Adobe", "product" => "Creative Cloud" },
          "Mara Rodriguez packaging"        => { "type" => "other",   "brand" => "Mara Rodriguez packaging" },
          "Innovation Hub"                  => { "type" => "other",   "brand" => "Innovation Hub" },
          "Next-Gen AI Technology"          => { "type" => "other",   "brand" => "Next-Gen AI Technology" },
          "Sustainable Farming Solutions"   => { "type" => "other",   "brand" => "Sustainable Farming Solutions" },
          "Digital Transformation Workshop" => { "type" => "other",   "brand" => "Digital Transformation Workshop" }
      }

      expectations.each do |brand_info, expected_output|
        report = Report.new(query: "best for consumers", brand_info: brand_info)
        topic_classification = Analysis::TopicClassification.new(report: report)
        VCR.use_cassette("analysis/topic_classification/#{brand_info.dasherize}") do
          topic_classification.perform
          assert_equal expected_output, topic_classification.topic
        end
      end
    end
  end
end
