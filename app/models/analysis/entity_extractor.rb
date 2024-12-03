# This class is responsible for extracting entities from the report's query and the AI assistant's response.
# The extraction is done in two passes:
# 1. First pass: Extracts entities from the AI assistant's response, including the type of the entity (brand, product, service, etc.), the name of the entity, the position of the entity in the answer, and any links related to the entity.
# 2. Second pass: Guesses the brands of the products found in the first pass.
class Analysis::EntityExtractor < Analysis::Step
    include Analysis::Inference

    attr_accessor :callback
    attribute :answers, :json, default: []
    validates :answers, length: { minimum: 1 }

    def perform
        first_pass_entities = self.first_pass
        second_pass_entities = self.second_pass(first_pass_entities)
        result = self.class.merge_passes(first_pass_entities, second_pass_entities)
        self.result = result
        true
    end

    def self.merge_passes(first_pass_entities, second_pass_entities)
        products_to_brands = {}.tap do |index|
            second_pass_entities["brands"].each do |brand|
                b = brand.with_indifferent_access
                b[:products].each do |product|
                    p = product.with_indifferent_access
                    index[p[:name]] = b[:name]
                end
            end
        end

        products = first_pass_entities["products"].map do |product|
            p = product.with_indifferent_access
            p["brand"] = products_to_brands[p[:name]]
            p
        end

        brand_name_to_products = products.inject({}) do |index, product|
            index[product[:brand]] ||= []
            index[product[:brand]] << product
            index
        end

        brands = brand_name_to_products.map do |brand_name, products|
            b = { name: brand_name }
            b.delete("type")
            b[:products] = products.map { |p| p[:name] }.uniq
            b[:links] = products.map { |p| p[:links] }.flatten.uniq
            b[:positions] = products.map { |p| p[:positions] }.flatten
            b
        end

        links = first_pass_entities["links"].map do |url, data|
            data = data.with_indifferent_access
            data[:brands] = data[:products].map { |b| products_to_brands[b] }.uniq.compact
            data.delete(:product_hits)
            data.delete(:brand_hits)
            [ url, data ]
        end

        { brands: brands, products: products, links: links }.with_indifferent_access
    end

    ##################
    ### First pass ###
    ##################

    FIRST_PASS_OUTPUT_SCHEMA = OpenAI::StructuredOutputs::Schema.new do
        define :link do
            string :url
        end

        define :entity do
            string :type, enum: %w[brand product service other], description: "The type of the entity, it's a commercial name associated to either a brand, product or service described in the query"
            string :name, description: "The name of the entity, like 'Apple' or 'Adidas Ultraboost 22' or 'Rolex Submariner Date'"
            number :position, description: "The position of the entity in the answer, the first entity appearing in the text is 1, the second 2, and so on"
            array :links, items: ref(:link), description: "Links related to the entity, used to include the entity in the particular answer to the given question"
        end

        array :entities, items: ref(:entity), description: "Entities found in the report's query"
        array :orphan_links, items: ref(:link), description: "Links that were not related to any particular entity"
    end

    FIRST_PASS_SYSTEM_PROMPTS = {
        eng: <<-EOF.promptize
            You are an assistant specialized in entity extraction.

            You are given a user query, and a response from an AI assistant about the user query comparing several brands or products related to the query.

            Your task is to extract:
            1. all the entities mentioned in the query and response that are commercial names associated to either a brand, product or service, including:
                1.1 The type of the entity, it's a commercial name associated to either a brand, product or service
                1.2 The name of the entity, like 'Apple' or 'Adidas Ultraboost 22' or 'Netflix'
                1.3 The position of the entity in the answer, the first entity appearing in the text is 1, the second 2, and so on.
                1.4 Any link related to the entity, that seems to be a source of information to include the entity in the particular answer to the given question.#{' '}
            2. A list of other links that are present in the text, but not related to any particular entity, called "orphan links"

            Entities should be present in the AI response, and not in the user query. Don't infer links or anything else, just extract the information from the AI response.

            Approach:
            * Make a first pass to find the most concrete entities, the products or models or particular services.
            * Now, take the products found in the first pass, and find the brands associated to them.
            * Return all the entities found in the first and second passes.

            Return as many entities and links as you can find in the given text.
        EOF
    }

    def first_pass
        entities = Concurrent::Promises.zip_futures_over(self.answers.to_a) do |pair|
            question = pair["question"]
            answer = pair["answer"]

            messages = [
                { role: :system, content: FIRST_PASS_SYSTEM_PROMPTS[self.language.to_sym] || FIRST_PASS_SYSTEM_PROMPTS[Analysis::DEFAULT_LANGUAGE] },
                { role: :user, content: first_pass_user_prompt(answer) }
            ]

            parameters = self.parameters(messages)
            parameters[:response_format] = FIRST_PASS_OUTPUT_SCHEMA

            res = client.parse(**parameters)
            self.callback&.call(res)

            if res.refusal.present?
                { error: res.refusal, messages: messages }
            else
                { ok: res.parsed }
            end
        end.value!
        self.class.aggregate_first_pass(entities)
    end

    def self.aggregate_first_pass(entities)
        ok, errors = entities.partition { |entity| entity[:ok].present? }

        if errors.length > ok.length
            raise errors.map { |e| e[:error] }.join("\n")
        elsif errors.any?
            Rails.logger.warn("Entity extraction failed for some #{errors.length} answers: #{errors.map { |e| e[:error] }.join("\n")}")
        end

        entities = ok.map { |entity| entity[:ok]["entities"] }.flatten

        brands, products = %w[brand product].map do |type|
            entities.select { |entity| entity["type"] == type }.inject({}) do |collection, entity|
                cname = entity["name"].downcase.gsub(/[^a-z0-9]+/, "")
                collection[cname] ||= []
                collection[cname] << entity
                collection
            end.map do |name, entities|
                {
                    name: entities.first["name"],
                    links: entities.map { |e| e["links"] }.flatten.map { |link| link["url"] },
                    positions: entities.map { |e| e["position"] }
                }.with_indifferent_access
            end
        end

        orphan_links = ok.map { |entity| entity[:ok]["orphan_links"] }.flatten.map { |link| link["url"] }


        brands.each do |brand|
            products.each do |product|
                if product[:name].downcase.include?(brand[:name].downcase)
                    product[:brand] = brand[:name]
                    brand[:products] ||= []
                    brand[:products] << product[:name]
                end
            end
        end

        links = {}
        brands.each do |brand|
            brand[:links].each do |link|
                links[link] ||= { product_hits: 0, brand_hits: 0, orphan_hits: 0, brands: [], products: [] }
                links[link][:brand_hits] += 1
                links[link][:brands] << brand[:name] unless links[link][:brands].include?(brand[:name])
            end
        end

        products.each do |product|
            product[:links].each do |link|
                links[link] ||= { product_hits: 0, brand_hits: 0, orphan_hits: 0, brands: [], products: [] }
                links[link][:product_hits] += 1
                links[link][:products] << product[:name] unless links[link][:products].include?(product[:name])
            end
        end

        orphan_links.each do |link|
            links[link] ||= { product_hits: 0, brand_hits: 0, orphan_hits: 0, brands: [], products: [] }
            links[link][:orphan_hits] += 1
        end

        { brands: brands, products: products, links: links }.with_indifferent_access
    end


    def first_pass_user_prompt(answer)
        <<-EOF.promptize
            query: #{self.report.query}
            AI assistant response: #{answer}
        EOF
    end


    ###################
    ### Second pass ###
    ###################

    SECOND_PASS_OUTPUT_SCHEMA = OpenAI::StructuredOutputs::Schema.new do
        define :product do
            string :name, description: "The name of the product, exactly as it appears in the input"
        end

        define :brand do
            string :name, description: "The name of the brand associated with the product"
            array :products, items: ref(:product), description: "Products associated with the brand"
        end

        array :brands, items: ref(:entity), description: "Brands found associated with the products"
    end

    # Define the system prompt for the second pass
    SECOND_PASS_SYSTEM_PROMPTS = {
    eng: <<-EOF.promptize
        You are an assistant specialized in identifying brands associated with products. You are given a list of products,
        and a set of already idenfied brands.

        Task:
        Given the names of products, identify the brands that manufactures or owns the product. If the brand is on the list of already identified brands,
        use it's exact name. If the brand is not on the list infer it from the product name.

        Instructions:
        - Return the brand as an entity with the following attributes:
        - type: 'brand'
        - name: the name of the brand (e.g., 'Apple', 'Adidas', 'Rolex')
        - products: the names of the products associated with the brand, exactly as they appear in the input
        - If the brand cannot be determined, do not return any entity.

        Output the entities using the specified schema.
    EOF
    }

    def second_pass(first_pass_entities)
        no_brands_found = { brands: [] }
        # Filter out product entities from the first pass
        products = first_pass_entities["products"]
        return no_brands_found if products.blank?

        product_names = products.map { |p| p.with_indifferent_access[:name] }
        already_known_brands = first_pass_entities["brands"].map { |b| b.with_indifferent_access[:name] }

        messages = [
            { role: :system, content: SECOND_PASS_SYSTEM_PROMPTS[self.language.to_sym] || SECOND_PASS_SYSTEM_PROMPTS[:eng] },
            { role: :user, content: second_pass_user_prompt(product_names, already_known_brands) }
        ]

        parameters = self.parameters(messages)
        parameters[:response_format] = SECOND_PASS_OUTPUT_SCHEMA

        res = client.parse(**parameters)
        self.callback&.call(res.parsed)

        if res.refusal.present?
            Rails.logger.error("Entity extraction failed for second pass: #{res.refusal}")
            no_brands_found
        else
            res.parsed
        end
    end

    def second_pass_user_prompt(product_names, already_known_brands)
        <<-EOF.promptize
            Extract the brands:

            products: #{product_names.join("\n * ")}
            <separator>
            already known brands: #{already_known_brands.join("\n * ")}
        EOF
    end
end
