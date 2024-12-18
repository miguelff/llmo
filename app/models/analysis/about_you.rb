class Analysis::AboutYou < Analysis::Step
    attribute :url, :string

    def input_is_valid
        if self.url.blank?
            self.errors.add(:url, "URL is required")
        end
    end

    def perform
        return false unless self.valid?
        website_info = Analysis::Website.perform_if_needed(self.analysis_id, url: self.url)

        if website_info.ok?
            brand_summary = Analysis::Brand.perform_if_needed(self.analysis_id, website_info: website_info.value!)
        end

        true
    end
end
