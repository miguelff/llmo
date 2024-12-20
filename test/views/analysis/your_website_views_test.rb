require "test_helper"

class Analysis::YourWebsiteViewsTest < ActionView::TestCase
  test "process your website: step failed" do
    analysis = Analysis::Record.create(status: :performing, next_action: :your_website_results)

    step = Analysis::YourWebsite.new(input: "https://unexistingsite.ggg", analysis: analysis)

    assert_raises(StandardError, /Could not fetch the page https:\/\/unexistingsite.ggg\//) do
      step.perform_with_retry(max_attempts: 1)
    end
    assert step.failed?
    assert_equal step.error, "Could not fetch the page https://unexistingsite.ggg"

    render partial: "analysis/your_website/results", locals: { your_website: step }
    assert_includes rendered, "Your website analysis failed."
  end

  test "process your website: step performing" do
    skip
  end

  test "process your website: step finished" do
    skip
  end
end
