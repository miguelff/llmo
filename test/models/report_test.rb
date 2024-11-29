require "test_helper"

class ReportTest < ActiveSupport::TestCase
    test "country code" do
        report = Report.new(region: "Spain")
        assert_equal "es-ES", report.country_code

        report = Report.new(region: "Martinique")
        assert_equal "fr-MQ", report.country_code
    end

    test "complete_analysis" do
        report = Report.create!(query: "What is the best laptop in the market?", cohort: "Software Engineering students", brand_info: "Dell XPS", owner: users(:jane))
        report.complete_analysis
        assert report.completed?, "Report should be completed"
        assert_equal 100, report.progress_percent
    end
end
