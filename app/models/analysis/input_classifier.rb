class Analysis::InputClassifier < Analysis::Step
    include Analysis::Inference

    SYSTEM_PROMPT = <<-EOF.promptize
        You are an assistant specialized in entity recognition.
        Your task is to analyze text and determine the category of the entity in the text.
        This is a list of entities we support:
            * brand: a brand name, like 'Apple', 'Samsung', 'Google', etc.
            * product: a product name, like 'iPhone', 'Galaxy', 'Pixel', etc.
            * service: A provided or subscribed offering, such as 'Netflix', 'Amazon Prime' or 'Uber'.

        If the entity includes both the brand and the product, return 'product' and set the brand accordingly. For example:
            * 'Apply iPhone 15 Pro Max' should be returned as a product with brand: 'Apple', product: 'iPhone 15 Pro Max'

        If the entity is a service, return 'service' and set the service accordingly. For example:
            * 'Netflix' should be returned as a service with brand name: 'Netflix'
            * 'Amazon Prime' should be returned as a service with brand name: 'Amazon', and product name: "Prime"

        If the entity is neither a brand nor a product, return 'other' and set the other accordingly. For example:
            * 'privacy' should be returned as other with value: 'privacy'
            * 'AI' should be returned as other with value: 'AI'

        Be sure to identify the entity type correctly, as it will be used to determine the next step in the analysis.
    EOF

    schema do
        string :entity_type, enum: %w[brand product service other], description: "The detected category for the input text"
        string :brand, required: false, description: "If it's a brand, the detected brand for the input text, if it's a product, the brand of or maker of the product"
        string :product, required: false, description: "If it's a product, the detected product for the input text, minus the brand, that must be included in the brand field"
        string :other, required: false, description: "If it's not a brand or product, the detected category for the input text"
    end

    system SYSTEM_PROMPT

    def perform
        res = chat("Input: #{self.report.brand_info}")
        unless res.refusal.present?
            self.result = self.class.normalize(res.parsed)
        else
            self.error = "Topic classification refused: #{res.refusal}, defaulting to entity_type=other"
            Rails.logger.error(self.error)
            self.result = { entity_type: "other", other: self.report.brand_info }
        end

        true
    end

    def self.normalize(res)
        _type = res[:entity_type]
        res = case _type
        when "brand"
            { brand: res[:brand] }
        when "product"
            { brand: res[:brand], product: res[:product] }
        when "service"
            { brand: res[:brand] }.tap do |h|
                h[:product] = res[:product] if res[:product].present?
            end
        else
            { brand: res[:other] }
        end
        res["type"] = _type
        res
    end
end
