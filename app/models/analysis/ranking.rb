class Analysis::Ranking < Analysis::Step
    include Analysis::Inference

    def self.cost(queries_count)
        Analysis::Step::COSTS[:inference]
    end

    attribute :entities, :json, default: {}
    attribute :input, :json, default: {}

    schema do
        number :product_rank, required: false, description: "The rank of the product"
        number :other_product_rank, required: false, description: "The rank of different product from the same brand"
        number :brand_rank, required: false, description: "The rank of the brand"
        string :reason, description: "A brief explanation for your ranking"
    end

    SYSTEM_PROMPT = <<-PROMPT
You are an expert in ranking brands and products. You are given two lists:
	  * Brand Leaders: A list of top brands with their scores and ranks,
	  * Product Leaders: A list of top products with their scores and ranks.

In both rankings 1 is highest ranked, 2 second hightest, etc.
Your task is to determine the rank of a given entity based on its performance.

Guidelines:
	1.	Identify the Entity Type:
	  * Brand: If the entity is a brand, compare it to the Brand Leaders.
	  * Product: If the entity is a product, compare it to the Product Leaders.
	  * Other: If the entity is neither a brand nor a product, compare it to both lists.
	2.	Ranking Rules:
	  * Exact Match:
	  * If the entity exactly matches a name in the appropriate list, use the corresponding rank.
	  * Similar Names:
	  * If the entity is the same as an item in the list but with a slight difference in the name (e.g., abbreviations, different wording), use its best rank.
	3.	Handling Similar Entities:
	  * Products with Slight Name Differences: Use the best rank if the product name differs slightly but refers to the same product.

    Example:
	  * Given the Product Leaders list:

      ```
        [
        { name: "MacBook Pro 16 (M3 Max)", rank: 1 },
        { name: "Dell XPS 15", rank: 2 },
        { name: "HP Spectre x360 14", rank: 3 },
        { name: "Asus ROG Zephyrus G14", rank: 4 },
        { name: "Lenovo ThinkPad X1 Carbon", rank: 5 },
        { name: "Microsoft Surface Laptop 5", rank: 6 },
        { name: "Acer Swift 3", rank: 7 },
        { name: "LG Gram 17", rank: 8 }
        ]
      ```

     * Given the Brand Leaders list:

      ```
        [
        { name: "Apple", rank: 1 },
        { name: "Dell", rank: 2 },
        { name: "HP", rank: 3 },
        { name: "Asus",  rank: 4 },
        { name: "Lenovo", rank: 5 },
        { name: "Microsoft", rank: 6 }
        ]
      ```

Some other examples:
* If given the product “MacBook Pro 16”, you should use product_rank: 1 because it’s a less specific version of “MacBook Pro 16 (M3 Max)”, and leave other_product_rank as 0, because there is no other product from the same brand.
* If given the product “MacBook Pro 14”, you should use other_product_rank: 1, as it’s another product from the same brand. If there is no other product from the same brand leave other_product_rank blank.
* If you don't have information about wether the product is from the same brand as another product, leave other_product_rank blank.

1.	Entity: { "type" => "product", "brand" => "apple", "product" => "Macbook Pro 16" }
  * product_rank: 1
  * brand_rank: 1
  * other_product_rank: Not applicable
  * explanation: Matches “MacBook Pro 16 (M3 Max)” in the Product Leaders list, Matches Apple in the Brand Leaders list, no other products from the same brands are in the ranking
2.	Entity: { "type" => "product", "brand" => "apple", "product" => "Macbook Pro 14" }
  * other_product_rank: 1
  * brand_rank: 1
  * product_rank: 0
  * Explanation: A product from the same brand as “MacBook Pro 16 (M3 Max)” but not the same product, the brand is in the first place.
3.  Entity: { "type" => "brand", "brand" => "apple" }
 * brand_rank: 1
 * other_product_rank: Not applicable
 * product_rank: 1
 * Explanation: Matches “Apple” in the Brand Leaders list, one of this brand's products (The MacBook Pro 16 (M3 Max)) is also in the first place, there are no other products from the same brand.
4.	Entity: { "type" => "product", "brand" => "apple", "product" => "MBP 16" }
  * brand_rank: 1
  * product_rank: 1
  * other_product_rank: Not applicable
  * Explanation: “MBP” is well-known to be a worldwide allias for "Macbook Pro", hence MBP 16 is the same as MacBook Pro 16, which is in the first place in the Product Leaders list.

Instructions:
  * Use the provided lists to determine the rank.
  * If the entity is unranked, don't feel any ranking field
  * Provide a brief explanation for your ranking
•   Note that the closer to number 1, the better the ranking.
PROMPT

    def perform
        rankings = { brands: brands_ranking, products: products_ranking }

        brand_leaders = rankings[:brands].map { |brand| { name: brand[:name], rank: brand[:rank] } }
        product_leaders = rankings[:products].map { |product| { name: product[:name], rank: product[:rank] } }

        self.temperature = 0.2

        res = chat(<<-PROMPT.promptize)
            [BrandsLeaders]
            #{brand_leaders.to_json}
            [/BrandLeaders]

            [ProductLeaders]
            #{product_leaders.to_json}
            [/ProductLeaders]

            [Input]
            #{input.to_json}
            [/Input]
        PROMPT

        unless res.refusal.present?
            self.result = rankings.merge(you: res.parsed)
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

        sorted = items.map { |item| { name: item[:name], score: item["positions"].map { |position| 1.0 / position rescue 0 }.sum } }.sort_by { |item| -item[:score] }
        max = sorted.first[:score]
        i = 0
        sorted.map { |item| item.merge(score: (50 + (item[:score] / max * 50)).round(2), rank: i += 1) }
    end
end
