require "test_helper"

class Analysis::LanguageDetectorTest < ActiveSupport::TestCase
  %w[eng spa fra deu ita].each do |language|
    test "perform for #{language}" do
      VCR.use_cassette("analysis/language_detector/#{language}") do
        report = reports("safe_cars_#{language}")
        analysis = Analysis::LanguageDetector.new(report: report)
        assert analysis.perform_and_save
        assert_equal language, analysis.result
      end
    end
  end
end
