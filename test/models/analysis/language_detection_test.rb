require "test_helper"

class Analysis::LanguageDetectionTest < ActiveSupport::TestCase
  test "perform" do
    VCR.use_cassette("language_detection") do
      report = reports(:safe_cars)
      analysis = Analysis::LanguageDetection.new(report: report)
      assert analysis.perform_and_save
      assert_equal "eng", analysis.language

      assert_equal "eng", report.reload.language_detection.language, "Language detection should be saved on the report"
    end
  end
end
