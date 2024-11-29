class Result::Ranks
    include Result::YourDetails
    include ChartsHelper

    def initialize(ranking:, entities:, input:)
        @entities = entities
        @ranking = ranking
        @input = input
    end

    def any_rank_present?
        relevant_ranks.length > 0
    end

    def relevant_ranks
        @relevant_ranks ||= begin
            relevant_ranks = []
            if input_is_product?
                relevant_ranks << :product
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
end
