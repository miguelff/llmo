require "test_helper"

class Analysis::TheWebsitePresenterTest < ActiveSupport::TestCase
    class YourWebsiteDouble < Struct.new(:result)
    end

    def presenter_for(res)
        result = Analysis::YourWebsite::Result.new(**res)
        Analysis::YourWebsitePresenter.new(YourWebsiteDouble.new(result))
    end

    test "everything is wrong" do
        presenter = presenter_for(title: nil, url: "https://example.com", toc: nil, meta_tags: nil)
        assert presenter.failed_checks.any?
        assert presenter.passed_checks.empty?
    end

    test "wrong title" do
        presenter = presenter_for(title: nil)

        check = presenter.title_check
        assert check.present?
        assert_equal check.name, "title"
        assert_not check.passed
    end

    test "ok title" do
        presenter = presenter_for(title: "Deurbe")
        assert presenter.passed_checks.any?

        check = presenter.title_check
        assert check.present?
        assert_equal check.name, "title"
        assert check.passed
        assert_equal check.description, "The website has a title tag"
    end

    test "no description" do
        presenter = presenter_for(title: "Deurbe")
        check = presenter.description_check
        assert check.present?
        assert_equal check.name, "description"
        assert_not check.passed
    end

    test "description is present" do
        presenter = presenter_for(title: "Deurbe", meta_tags: { "description" => "Deurbe es una empresa de desarrollo de software" })
        check = presenter.description_check
        assert check.present?
        assert_equal check.name, "description"
        assert check.passed
        assert_equal check.description, "The website has a description meta tag"
    end

    test "description is present with different casing" do
        presenter = presenter_for(title: "Deurbe", meta_tags: { "  Description " => "Deurbe es una empresa de desarrollo de software" })
        check = presenter.description_check
        assert check.present?
        assert_equal check.name, "description"
        assert check.passed
        assert_equal check.description, "The website has a description meta tag"
    end
end
