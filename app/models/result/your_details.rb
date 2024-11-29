module Result::YourDetails
    extend ActiveSupport::Concern

    def your_logo_url
        response = Faraday.get("https://api.logo.dev/search?q=#{your_brand}", nil, { "Authorization" => "Bearer: sk_ZcGYOz3AQBeYLzroGg3HUw" })
        logos = JSON.parse(response.body)
        logo = logos.find { |logo| logo["name"].casecmp?(your_brand) }
        logo ? logo["logo_url"] : nil
    end

    def input_is_brand?
        @input["type"] == "brand"
    end

    def input_is_product?
        @input["type"] == "product"
    end

    def rank?
        product_rank.present? || brand_rank.present? || other_products_rank.present?
    end

     def your_brand
        @input["brand"]
    end

    def your_product
        product_name = @input["product"]
        return nil if product_name.blank?
        return product_name if product_name.downcase.include?(your_brand.downcase)

        parts = [ your_brand, product_name ].compact
        return nil if parts.empty?
        parts.join(" ")
    end

    def brand_rank
        @ranking["you"]["brand_rank"]
    end

    def product_rank
        @ranking["you"]["product_rank"]
    end

    def other_products_rank
        @ranking["you"]["other_products_rank"]
    end

    def best_product_rank
        [ product_rank, other_products_rank ].compact.min
    end

    def any_product_rank
        if product_rank || other_products_rank
            [ product_rank, other_products_rank ].compact.max
        end
    end
end
