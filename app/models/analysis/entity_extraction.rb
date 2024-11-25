class Analysis::EntityExtraction < Analysis::Step
    include Analysis::Inference

    attribute :answers, :json, default: []
    validates :answers, length: { minimum: 1 }

    attribute :topic, :json, default: -> { { type: "brand", brand: self.report.brand_info } }

    STEP_1_SCHEMA = OpenAI::StructuredOutputs::Schema.new do
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

    STEP_1_SYSTEM = {
        eng: <<-EOF.squish
            You are an assistant specialized in entity extraction.

            You are given a user query, and a response from an AI assistant about the user query comparing several brands or products related to the query.

            Your task is to extract:
            1. all the entities mentioned in the query and response that are commercial names associated to either a brand, product or service, including:
                1.1 The type of the entity, it's a commercial name associated to either a brand, product or service
                1.2 The name of the entity, like 'Apple' or 'Adidas Ultraboost 22' or 'Netflix'
                1.3 The position of the entity in the answer, the first entity appearing in the text is 1, the second 2, and so on.
                1.4 Any link related to the entity, that seems to be a source of information to include the entity in the particular answer to the given question
            2. A list of other links that are present in the text, but not related to any particular entity, called "orphan links"

            Approach:
            * Find the most concrete entities first, if things are described grouped by brand, and an entity is a product or model, include the brand name in the entity. For intance, if the text is talking about "best laptop in the market",
            and the text, talks about "Macbook Air", and you know that "Macbook Air" is a product from "Apple", then the entity should be "Apple Macbook Air".#{' '}
            * Then, find the less concrete entities, like brands, or company names.
            * Don't include brand or company names if they are not associated to a product or service described in the query.

            Return as many entities and links as you can find in the given text.
        EOF
    }

    def perform
        entities = self.answers.map do |question, answer|
            step1_system_prompt = STEP_1_SYSTEM[self.language.to_sym] || STEP_1_SYSTEM[Analysis::DEFAULT_LANGUAGE]
            messages = [ { role: :system, content: step1_system_prompt }, { role: :user, content: user_prompt(answer) } ]

            parameters = self.parameters(messages)
            parameters[:response_format] = STEP_1_SCHEMA


            res = client.parse(**parameters)
            if res.refusal.present?
                { error: res.refusal, messages: messages }
            else
                { ok: res.parsed }
            end
        end

        self.result = self.class.aggregate(entities)

        true
    end

    def self.aggregate(entities)
        ok, errors = entities.partition { |entity| entity[:ok].present? }

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
            links[link] ||= { count: 0, brands: [], products: [] }
            links[link][:orphan_hits] += 1
        end

        { brands: brands, products: products, links: links }.with_indifferent_access
    end


    def user_prompt(answer)
        <<-EOF.squish
            query: #{self.report.query}
            AI assistant response: #{answer}
        EOF
    end
end
