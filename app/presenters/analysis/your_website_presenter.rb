class Analysis::YourWebsitePresenter < ApplicationPresenter
    attr_reader :your_website
    delegate :result, to: :your_website, allow_nil: true

    class CheckResult < Struct.new(:name, :passed, :description)
    end

    CHECKS = [
        :title,
        :description
      # :open_graph,
      # :canonical,
      # :viewport,
      # :stale_tags,
      # :header_og,
      # :header_og_image,
      # :header_og_image_alt,
      # :header_og_image_width,
      # :header_og_image_height
    ]

    def initialize(your_website)
        @your_website = your_website
    end

    def failed_checks
        Hash[checks.reject { |_, check| check.passed }]
    end

    def passed_checks
        Hash[checks.select { |_, check| check.passed }]
    end

    def checks
        @checks ||= Hash[CHECKS.map do |check|
            [ check, send("#{check}_check") ]
        end]
    end

    def title_check
        title = result.title
        if title.blank?
            CheckResult.new("title", false, "The website is missing a <span class='tag'>&lt;title&gt;</span> tag.".html_safe)
        else
            CheckResult.new("title", true, "The website has a title tag")
        end
    end

    def description_check
        description = result.meta_tags&.find { |k, v| k.strip.downcase == "description" }&.last

        if description.blank?
            CheckResult.new("description", false, "The website is missing a high quality <span class='tag'>&lt;meta name=\"description\"&gt;</span> tag. <a target='_blank' class='underline' href='https://developers.google.com/search/docs/appearance/snippet?hl=es#use-quality-descriptions'>Learn more</a>".html_safe)
        else
            CheckResult.new("description", true, "The website has a description meta tag")
        end
    end

    def header_check
        @your_website.result["header"]
    end
end
