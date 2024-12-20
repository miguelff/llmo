require "test_helper"

class AnalysisControllerTest < ActionDispatch::IntegrationTest
  setup do
    delete cancel_analysis_path
  end

  test "should destroy analysis" do
    get root_path
    assert Analysis::Record.last.pending?
    delete cancel_analysis_path
    assert_redirected_to root_path
    assert Analysis::Record.last.canceled?
  end

  test "sets a new analysis in session after cancelling the current one" do
    get root_path

    analysis_id = Analysis::Record.last.id
    assert_equal session[:analysis_id], analysis_id

    delete cancel_analysis_path
    get root_path
    assert_equal session[:analysis_id], Analysis::Record.last.id
    assert_not_equal session[:analysis_id], analysis_id
  end

  test "your website" do
    get your_website_path
    assert_response :success
    assert_equal session[:analysis_id], Analysis::Record.last.id
  end

  # See view tests at test/views/analysis/your_website_test.rb for non-happy paths
  test "process your website: Happy path" do
    get your_website_path

    current_analysis = Analysis::Record.last
    assert_equal session[:analysis_id], current_analysis.id
    post process_your_website_path, params: { analysis_your_website_form: { url: "https://www.google.com" } }

    assert_redirected_to your_website_results_path
    assert_equal session[:analysis_id], current_analysis.id
    assert current_analysis.reload.performing?
    assert_equal current_analysis.next_action, "your_website_results"
    assert_equal current_analysis.steps.count, 1

    assert_enqueued_with(job: AnalysisStepJob, args: [ current_analysis.steps.first ])

    get your_website_results_path
    assert_response :success
    assert_includes response.body, "Your website analysis is in progress"
  end

  test "redirects to last progress step" do
    get your_website_path
    post process_your_website_path, params: { analysis_your_website_form: { url: "https://www.google.com" } }
    assert_redirected_to your_website_results_path

    get your_website_path
    assert_redirected_to your_website_results_path
  end
end
