require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @report = reports(:safe_cars)
  end

  test "should create report" do
    assert_difference("Report.count") do
      post reports_url, params: { report: { query: @report.query, cohort: @report.cohort, brand_info: @report.brand_info, region: @report.region } }
    end

    report = Report.last
    assert_equal report.query, @report.query
    assert_equal report.advanced_settings, @report.advanced_settings
    assert_equal "Women 45+", report.cohort
    assert_equal "Volvo XC40", report.brand_info
    assert_equal "any", report.region
    assert_equal "pending", report.status

    assert_redirected_to report_url(Report.last)
  end
end
