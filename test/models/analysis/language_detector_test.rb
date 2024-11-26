require "test_helper"

class Analysis::LanguageDetectorTest < ActiveSupport::TestCase
  test "perform" do
    VCR.use_cassette("analysis/language_detector") do
      report = reports(:safe_cars)
      analysis = Analysis::LanguageDetector.new(report: report)
      assert analysis.perform_and_save
      assert_equal "eng", analysis.result
    end
  end
end
