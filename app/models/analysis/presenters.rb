module Analysis::Presenters
    class WebsiteInfo < Struct.new(:url, :title, :toc, :meta_tags)
        def to_h
        { url: url, title: title, toc: toc, meta_tags: meta_tags }
        end
    end

     class BrandSummaryFromWebsiteInfo < Struct.new(:brand, :category, :description, :market, :competitors)
        def to_h
            { brand: brand, category: category, description: description, market: market, competitors: competitors }
        end

        def complete?
            brand.present? && category.present? && description.present? && market.present? && competitors.present?
        end
     end
end
