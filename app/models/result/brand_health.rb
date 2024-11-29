class Result::BrandHealth
    include Result::YourDetails

    def initialize(ranking, input)
      @ranking = ranking
      @input = input
    end

    def indicator_details
        @indicator_details ||= if !input_is_product?
            if brand_rank.present?
                if brand_rank == 1
                    { summary: "best", remarks: "Your brand is the best in the market." }
                elsif brand_rank <= 10
                    { summary: "excellent", remarks: "Your brand is among the top-10 of the market" }
                elsif any_product_rank.present? && any_product_rank <= 10
                    { summary: "good", remarks: "Your brand has some products in the #{any_product_rank.ordinalize} position" }
                else
                    { summary: "neutral", remarks: "Your brand is the #{brand_rank.ordinalize} in the market" }
                end
            elsif any_product_rank.present?
                { summary: "good", remarks: "Your brand has some products in the #{any_product_rank.ordinalize} position among the market leaders" }
            else
                { summary: "bad", remarks: "Your brand is not among the market leaders" }
            end
        else
            if product_rank.present?
                if product_rank == 1
                    { summary: "best", remarks: "Your product is the best in the market." }
                elsif product_rank <= 10
                    { summary: "excellent", remarks: "Your product is among the top-10 of the market" }
                else
                    { summary: "good", remarks: "Your product is ranked #{product_rank.ordinalize} in the market" }
                end
            else
                { summary: "bad", remarks: "Your product is not among the market leaders" }
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
