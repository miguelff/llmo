require "test_helper"

class Analysis::YourWebsiteViewsTest < ActionView::TestCase
  test "process your website: failed" do
    analysis = Analysis::Record.create(status: :performing, next_action: :your_website_results)

    step = Analysis::YourWebsite.new(input: "https://unexistingsite.ggg", analysis: analysis)

    assert_raises(StandardError, /Could not fetch the page https:\/\/unexistingsite.ggg\//) do
      step.perform_with_retry(max_attempts: 1)
    end
    assert step.failed?
    assert_equal step.error, "Could not fetch the page https://unexistingsite.ggg"

    render partial: "analysis/your_website/status", locals: { your_website: step }
    assert_includes rendered, "Your website analysis failed."
  end

  test "process your website: performing" do
    analysis = Analysis::Record.create(status: :performing, next_action: :your_website_results)

    step = Analysis::YourWebsite.new(input: "https://www.example.com", analysis: analysis)
    step.performing!

    render partial: "analysis/your_website/status", locals: { your_website: step }
    assert_includes rendered, "Your website analysis is in progress"
  end

  test "process your website: finished" do
    analysis = Analysis::Record.create(status: :finished, next_action: :your_website_results)

    VCR.use_cassette("analysis/brand/tablassurfshop.com") do
      step = Analysis::YourWebsite.new(input: "https://www.tablassurfshop.com", analysis: analysis)
      step.perform_with_retry
      render partial: "analysis/your_website/status", locals: { your_website: step }
      assert_includes rendered, "Your website has no outstanding structural issues"
    end
  end
end
