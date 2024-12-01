class Analysis::Ranking < Analysis::Step
    include Analysis::Inference

    def self.cost(queries_count)
        Analysis::Step::COSTS[:inference]
    end

    self.model = "gpt-4o"
    self.temperature = 0.0
    attribute :entities, :json, default: {}

    schema do
        number :product_rank, required: false, description: "The rank of the product"
        number :other_products_rank, required: false, description: "The best rank of a different product from the same brand"
        number :brand_rank, required: false, description: "The rank of the brand"
        string :reason, description: "A brief explanation for your ranking"
    end

    system <<-PROMPT.promptize
  You are an expert in ranking brands and products. You are given two lists:
	  * BrandLeaders: A list of top brands with their ranks,
	  * ProductLeaders: A list of top products with their ranks.

    And an input, which contains some brand / product / service information.

    In both rankings 1 is highest ranked, 2 second hightest, etc.
    Your task is to determine three ranks of a given entity based on its performance.

    You need to determine the following ranks:
    * product_rank: If the rank is a product, it's rank among the product leaders.
    * brand_rank: If the rank is a brand, it's rank among the brand leaders, if it's a product, the rank of the brand that makes the product
    * other_products_rank: the best rank among the ranks of other products from the same brand, but those products MUST not be the same as the one in the input, subject of the product rank.
     If there are no other products from the same brand, the rank should be 0. As a consequence, this rank cannot be the same as the product rank.

    When you compare products, two products with slight variations, like "BMW Serie 2" and "BMW Serie 2 Active Tourer" are considered the same product. However, "BMW Serie 2" and "BMW Serie 3" are considered different products.
    All the results are optional, if there is no information about the input, or there are no products or brands related to it in the ranking, you can leave the rank blank.

    Don't use any other information than the ones provided in the input.
  PROMPT

    def perform
        rankings = { brands: brands_ranking, products: products_ranking }

        brand_leaders = rankings[:brands].map { |brand| { name: brand[:name], rank: brand[:rank] } }
        product_leaders = rankings[:products].map { |product| { name: product[:name], rank: product[:rank] } }

        user_prompt = <<-PROMPT.promptize
            [BrandsLeaders]
            #{brand_leaders.to_json}
            [/BrandLeaders]

            [ProductLeaders]
            #{product_leaders.to_json}
            [/ProductLeaders]

            [Input]
            #{report.brand_info}
            [/Input]
        PROMPT

        res = chat(user_prompt)

        unless res.refusal.present?
            parsed = res.parsed.with_indifferent_access
            parsed[:product_rank] = nil if (parsed[:product_rank].blank? || !parsed[:product_rank].to_i.positive? rescue nil)
            parsed[:brand_rank] = nil if (parsed[:brand_rank].blank? || !parsed[:brand_rank].to_i.positive? rescue nil)
            parsed[:other_products_rank] = nil if (parsed[:other_products_rank].blank? || !parsed[:other_products_rank].to_i.positive? rescue nil)
            self.result = rankings.merge(you: parsed)
        else
            self.error = res.refusal
        end

        true
    end

    def brands_ranking
        ranking("brands")
    end

    def products_ranking
        ranking("products")
    end

    def ranking(_type)
        items = entities.with_indifferent_access[_type]
        return [] if items.blank?

        sorted = items.reject { |item| item[:name].blank? }
                      .map { |item| { name: item[:name], score: item["positions"].map { |position| 1.0 / position rescue 0 }.sum } }
                      .sort_by { |item| -item[:score] }

        max = sorted.first[:score]
        i = 0
        sorted.map { |item| item.merge(score: (50 + (item[:score] / max * 50)).round(2), rank: i += 1) }
    end
end
