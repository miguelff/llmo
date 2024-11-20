require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @report = reports(:safe_cars)
    sign_in users(:jane)
  end

  test "should create report" do
    assert_difference("Report.count") do
      post reports_url, params: { report: { query: @report.query, cohort: @report.cohort, brand_info: @report.brand_info, region: @report.region } }
    end

    report = Report.order(created_at: :desc).first
    assert_equal "Women 45+", report.cohort
    assert_equal "Volvo XC40", report.brand_info
    assert_equal "any", report.region
    assert_equal "pending", report.status

    assert_redirected_to report_url(report)
  end
end
