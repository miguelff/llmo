require "test_helper"

class AnalysisControllerTest < ActionDispatch::IntegrationTest
  test "gets redirected to one if no analysis_id in session" do
    post analysis_two_url
    assert_response :redirect
    assert_redirected_to action: :one
  end

  test "sets analysis_id in session if no analysis_id in session" do
    post analysis_one_url
    assert_response :success
    assert_equal session[:analysis_id], Analysis::Record.last.id.to_s

    post analysis_two_url
    assert_response :success
    assert_equal session[:analysis_id], Analysis::Record.last.id.to_s
  end
end
