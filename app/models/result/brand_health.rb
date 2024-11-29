class Result::BrandHealth
    include Result::YourDetails

    def initialize(ranking:, entities:, input:)
        @entities = entities
        @ranking = ranking
        @input = input
    end

    def indicator_details
        @indicator_details ||= if !input_is_product?
            if brand_rank.present?
                if brand_rank == 1
                    { summary: "best", remarks: "<strong>#{your_brand}</strong> is the best in the market.".html_safe }
                elsif brand_rank <= 10
                    { summary: "excellent", remarks: "<strong>#{your_brand}</strong> is among the top-10 of the market".html_safe }
                elsif any_product_rank.present? && any_product_rank <= 10
                    { summary: "good", remarks: "<strong>#{your_brand}</strong> has some products in the <strong>#{any_product_rank.ordinalize}</strong> position".html_safe }
                else
                    { summary: "neutral", remarks: "<strong>#{your_brand}</strong> is the <strong>#{brand_rank.ordinalize}</strong> in the market".html_safe }
                end
            elsif any_product_rank.present?
                { summary: "good", remarks: "<strong>#{your_brand}</strong> has some products in the <strong>#{any_product_rank.ordinalize}</strong> position among the market leaders".html_safe }
            else
                { summary: "bad", remarks: "<strong>#{your_brand}</strong> is not among the market leaders".html_safe }
            end
        else
            if product_rank.present?
                if product_rank == 1
                    { summary: "best", remarks: "<strong>#{your_product}</strong> is the best in the market.".html_safe }
                elsif product_rank <= 10
                    { summary: "excellent", remarks: "<strong>#{your_product}</strong> is among the top-10 of the market".html_safe }
                else
                    { summary: "good", remarks: "<strong>#{your_product}</strong> is ranked <strong>#{product_rank.ordinalize}</strong> in the market".html_safe }
                end
            elsif brand_rank.present?
                { summary: "good", remarks: "<strong>#{your_product}</strong> doesn't appear directly in the ranks, but <strong>#{your_brand}</strong> is the <strong>#{brand_rank.ordinalize}</strong> in the market".html_safe }
            else
                { summary: "bad", remarks: "<strong>#{your_product}</strong> is not among the market leaders".html_safe }
            end
        end
    end

    def indicator
        indicator_details[:summary]
    end

    def indicator_remarks
        indicator_details[:remarks]
    end

    def remarks
        @ranking["you"]["reason"]
    end
end
