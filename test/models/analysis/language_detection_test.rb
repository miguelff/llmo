require "test_helper"

class Analysis::LanguageDetectionTest < ActiveSupport::TestCase
  test "perform" do
    report = reports(:safe_cars)
    analysis = Analysis::LanguageDetection.new(report: report)
    assert analysis.perform_and_save
    assert_equal "eng", analysis.language
  end
end
