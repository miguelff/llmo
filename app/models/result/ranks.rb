class Result::Ranks
    include Result::YourDetails
    include ChartsHelper

    def initialize(ranking:, entities:, input:)
        @entities = entities
        @ranking = ranking
        @input = input
    end

    def any_rank_present?
        relevant_ranks.map { |name| rank(name) }.compact.any?
    end

    def relevant_ranks
        @relevant_ranks ||= begin
            relevant_ranks = []
            if input_is_product?
                relevant_ranks << :product if product_rank.present?
                relevant_ranks << :brand if @input["brand"].present?
                if other_products_rank.present? && (product_rank.blank? || other_products_rank < product_rank)
                    relevant_ranks << :other_products
                end
            else
                relevant_ranks << :brand
                relevant_ranks << :best_product
            end

            relevant_ranks
        end
    end

    def rank(type)
        send("#{type}_rank")
    end

    def rank_title(type)
        send("#{type}_rank_title")
    end

    def rank_remarks(type)
        nil unless rank(type).present?
        send("#{type}_rank_remarks")
    end

    def product_rank_title
        "Your Product"
    end

    def brand_rank_title
        "Your Brand"
    end

    def best_product_rank_title
        "Best Product"
    end

    def other_products_rank_title
        "Other Products"
    end

    def product_rank_remarks
        return nil unless product_rank.present?
        if product_rank == 1
            "Your product is the best in the market."
        else
            before = @ranking["products"][product_rank - 2]["name"]
            message = "Your product is the #{product_rank.ordinalize} in the market"
            message += ", <strong>right after #{before}</strong>." if before.present?
            message.html_safe
        end
    end

    def brand_rank_remarks
        return nil unless brand_rank.present?
        if brand_rank == 1
            "Your brand is the best in the market."
        else
            before = @ranking["brands"][brand_rank - 2]["name"] rescue nil
            message = "Your brand is the #{brand_rank.ordinalize} in the market"
            message += ", <strong>right after #{before}</strong>." if before.present?
            message.html_safe
        end
    end

    def best_product_rank_remarks
        return nil unless best_product_rank.present?
        best_product = @ranking["products"][best_product_rank - 1]["name"] rescue nil
        if best_product_rank == 1
            "Your brand has the best product in the market: #{best_product}"
        else
            "Your brand has the #{best_product_rank.ordinalize} best product in the market: #{best_product}"
        end
    end

    def other_products_rank_remarks
        return nil unless other_products_rank.present?
        best_product = @ranking["products"][other_products_rank - 1]["name"]
        "The best ranking for any of your products is that of #{best_product}, in the #{other_products_rank.ordinalize} place."
    end
end
