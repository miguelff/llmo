module Result::YourDetails
    extend ActiveSupport::Concern

    def input_is_brand?
        @input["type"] == "brand"
    end

    def input_is_product?
        @input["type"] == "product"
    end

    def rank?
        product_rank.present? || brand_rank.present? || other_product_rank.present?
    end

    def product_rank
        rank = @ranking["you"]["product_rank"]
        rank.present? && rank > 0 ? rank : nil
    end

    def product_score
        return nil unless product_rank.present?
        @ranking["products"][product_rank - 1]["score"]
    end

    def brand_rank
        rank = @ranking["you"]["brand_rank"]
        rank.present? && rank > 0 ? rank : nil
    end

    def brand_score
        return nil unless brand_rank.present?
        @ranking["products"][brand_rank - 1]["score"]
    end

    def other_product_rank
        rank = @ranking["you"]["other_product_rank"]
        rank.present? && rank > 0 ? rank : nil
    end

    def other_product_score
        return nil unless other_product_rank.present?
        @ranking["products"][other_product_rank - 1]["score"]
    end

    def any_product_rank
        if product_rank || other_product_rank
            [ product_rank, other_product_rank ].compact.max
        end
    end

    def score?
        product_score.present? || brand_score.present? || other_product_score.present?
    end

    def product_score
        if product_rank.present?
            @ranking["products"][product_rank - 1]["score"] rescue nil
        end
    end

    def brand_score
        if brand_rank.present?
            @ranking["products"][brand_rank - 1]["score"] rescue nil
        end
    end

    def other_product_score
        if other_product_rank.present?
            @ranking["products"][other_product_rank - 1]["score"] rescue nil
        end
    end
end
