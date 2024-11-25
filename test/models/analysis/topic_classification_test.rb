require "test_helper"

class Analysis::TopicClassificationTest < ActiveSupport::TestCase
    test "topic classification" do
      VCR.use_cassette("analysis/topic_classification") do
        expectations = {
          "Samsung"                   => { "brand"   => "Samsung" },
          "Nike"                      => { "brand"   => "Nike" },
          "Tesla"                     => { "brand"   => "Tesla" },
          "Gucci"                     => { "brand"   => "Gucci" },
          "Microsoft"                 => { "brand"   => "Microsoft" },
          "Tesla Model 3"             => { "brand"   => "Tesla",   "product" => "Model 3" },
          "iPhone 15 Pro Max"         => { "brand"   => "Apple",   "product" => "iPhone 15 Pro Max" },
          "Sony WH-1000XM5"           => { "brand"   => "Sony",    "product" => "WH-1000XM5" },
          "LG B4 OLED TV"             => { "brand"   => "LG",      "product" => "B4 OLED TV" },
          "Adidas Ultraboost 22"      => { "brand"   => "Adidas",  "product" => "Ultraboost 22" },
          "Volvo XC40"                => { "brand"   => "Volvo",   "product" => "XC40" },
          "Dell XPS 13"               => { "brand"   => "Dell",    "product" => "XPS 13" },
          "Canon EOS R5"              => { "brand"   => "Canon",   "product" => "EOS R5" },
          "Bose QuietComfort 45"      => { "brand"   => "Bose",    "product" => "QuietComfort 45" },
          "MacBook Air M2"            => { "brand"   => "Apple",   "product" => "MacBook Air M2" },
          "Netflix"                   => { "brand"   => "Netflix" },
          "Spotify Premium"           => { "brand"   => "Spotify", "product" => "Premium" },
          "Amazon Web Services"       => { "brand"   => "Amazon",  "product" => "Web Services" },
          "Uber Eats"                 => { "brand"   => "Uber",    "product" => "Eats" },
          "Adobe Creative Cloud"      => { "brand"   => "Adobe",   "product" => "Creative Cloud" },
          "Mara Rodriguez packaging"  => { "other"   => "Mara Rodriguez packaging" },
          "Innovation Hub"            => { "other"   => "Innovation Hub" },
          "Next-Gen AI Technology"    => { "other"   => "Next-Gen AI Technology" },
          "Sustainable Farming Solutions"   => { "other"   => "Sustainable Farming Solutions" },
          "Digital Transformation Workshop" => { "other" => "Digital Transformation Workshop" }
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
