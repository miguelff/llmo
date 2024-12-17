module Analysis::Presenters
    class WebsiteInfo < Struct.new(:url, :title, :toc, :meta_tags)
        def to_h
        { url: url, title: title, toc: toc, meta_tags: meta_tags }
        end

        def self.from_json(json)
            h = json.with_indifferent_access
            new(
                url: h.dig(:url),
                title: h.dig(:title),
                toc: h.dig(:toc),
                meta_tags: h.dig(:meta_tags)
            )
        end

        def to_prompt
            <<~PROMPT.promptize
                # Website info

                ## URL: #{url}
                ## Title: #{title}
                ## Meta tags:#{' '}
                #{meta_tags.map { |k, v| "* #{k}: #{v}" }.join("\n\t\t\t")}

                ## HMTL header elements (as a table of contents of the site):
                #{toc}
            PROMPT
        end
    end

    class BrandBasicInfo < Struct.new(:name, :category, :description, :region, :keywords)
        def to_h
            { name: name, category: category, description: description, region: region, keywords: keywords }
        end

        def flattened_keywords
           keywords&.map(&:values)&.flatten rescue []
        end

        def to_prompt
            prompt = "# Brand basic info\n"
            prompt += "## Name: #{name}\n" if name.present?
            prompt += "## Category: #{category}\n" if category.present?
            prompt += "## Description: #{description}\n" if description.present?
            prompt += "## Region: #{region}\n" if region.present?
            prompt += "## Keywords (comma separated): #{flattened_keywords&.join(", ")}\n" if keywords.present?
            prompt
        end

        def with_competitors(competitors)
            BrandInfo.new(self, competitors)
        end

        def complete?
            name.present? && category.present? && description.present? && region.present? && keywords.present?
        end
    end

    class BrandInfo
        attr_reader :basic_info, :competitors

        def initialize(basic_info, competitors)
            @basic_info = basic_info
            @competitors = competitors
        end

        def to_h
            basic_info.to_h.merge(competitors: competitors)
        end

        def complete?
            basic_info.complete? && competitors.present?
        end

        def self.from_json(json)
            h = json.with_indifferent_access
            basic_info = BrandBasicInfo.new(
                h.dig(:name),
                h.dig(:category),
                h.dig(:description),
                h.dig(:region),
                h.dig(:keywords)
            )
            competitors = h.dig(:competitors)
            new(basic_info, competitors)
        end
    end
end
