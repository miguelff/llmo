require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @report = reports(:safe_cars)
  end

  test "should create report" do
    assert_difference("Report.count") do
      post reports_url, params: { report: { advanced_settings: @report.advanced_settings, query: @report.query } }
    end

    report = Report.last
    assert_equal report.query, @report.query
    assert_equal report.advanced_settings, @report.advanced_settings
    assert_redirected_to report_url(Report.last)
  end
end
