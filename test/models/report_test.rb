require "test_helper"

class ReportTest < ActiveSupport::TestCase
    test "country code" do
        report = Report.new(region: "Spain")
        assert_equal "es-ES", report.country_code

        report = Report.new(region: "Martinique")
        assert_equal "fr-MQ", report.country_code
    end
end
