class Analysis::TopicFeatures < Analysis::Step
    # The result of entity extraction
    attribute :entities, :json, default: {}
    validates :entities, presence: true

    # The result of topic classification
    attribute :topic, :json, default: {}
    validates :topic, presence: true

    attribute :answers, :json, default: []
    validates :answers, presence: true

    # The result of language detection
    attribute :language, :string, default: Analysis::DEFAULT_LANGUAGE

    def perform
        begin
            self.result = {}.tap do |result|
                result[:overarching_term] = overarching_term
                result[:term_attributes] = term_attributes
                result[:competition_scores] = competition_scores
            end
        rescue => e
            Rails.logger.error("Error performing topic features: #{e.message}")
            self.error = e
        end

        true
    end

    def perform_and_save
        self.perform && self.save
    end

    def overarching_term
        @overarching_term ||= OverarchingTerm.new.tap do |builder|
            builder.report = report
            builder.entities = entities
            builder.topic = topic
            builder.language = language
            # OpenAI
            builder.provider = provider
            builder.model = model
            builder.temperature = temperature
        end.perform
    end

    def term_attributes
        @term_attributes ||= TermAttributes.new.tap do |builder|
            builder.overarching_term = overarching_term
            builder.language = language

            builder.provider = provider
            builder.model = model
            builder.temperature = temperature
        end.perform
    end

    def competition_scores
        CompetitionScores.new.tap do |builder|
            builder.overarching_term = overarching_term
            builder.term_attributes = term_attributes
            builder.entities = entities

            builder.topic = topic
            builder.answers = answers
            builder.language = language

            builder.provider = provider
            builder.model = model
            builder.temperature = temperature
        end.perform
    end

    class CompetitionScores
        include Analysis::Inference

        attr_accessor :overarching_term, :term_attributes, :entities, :topic, :answers, :language, :provider, :model, :temperature

        self.model = "gpt-4o-mini"

        system <<-EOF.promptize
            You are an AI agent specialized in evaluating and scoring competitors based on specific criteria.
            You will be provided with:
                1.	A list of brands or products to evaluate, between <overarching_term> and </overarching_term>.
                2.	A set of attributes or criteria to assess these competitors, between <term_attributes> and </term_attributes>.
                3.	Relevant knowledge about the competitors, along with information on other products or brands that may not directly compete, between <answers> and </answers>.

            Your goal is to accurately evaluate and score the competitors against the provided attributes, ensuring that your assessments are clear, fair, and well-reasoned. Distinguish competitors from non-competitors where necessary.#{'            '}
        EOF

        schema do
            define :score do
                string :attribute, required: true, description: "The name of the attribute"
                string :score, required: true, description: "The score of the competitor for the attribute, n/10, where n is an integer between 0 and 10"
                string :reason, required: true, description: "The reason for the score"
            end

            define :competitor do
                string :name, required: true, description: "The name of the competitor"
                array :scores, items: ref(:score), description: "The scores of the competitor"
            end

            array :competitors, items: ref(:competitor), description: "The competitors and their scores"
        end

        def perform
            res =chat(<<-PROMPT.promptize)
                <overarching_term>
                #{overarching_term}
                </overarching_term>

                <term_attributes>
                #{term_attributes}
                </term_attributes>

                <competitors>
                #{competitors(topic, entities)}
                </competitors>

                <answers>
                #{answers}
                </answers>
            PROMPT

            res.parsed.competitors
        end

        def competitors(topic, entities)
            # TODO: score competitors take the top 5
            competitors = entities[(topic["type"] || "brand").pluralize].map { |entity| entity["name"] }.slice(0, 5)
            competitors << (topic["type"] == "product" ? " #{topic["brand"]} #{topic["product"]}" : " #{topic["brand"]}")
            competitors.join(", ")
        end
    end

    class OverarchingTerm
        include Analysis::Inference

        attr_accessor :report, :entities, :topic, :language, :provider, :model, :temperature

        system <<-EOF
You are an AI agent specializing in identifying appropriate overarching terms for a set of products or brands based on a user’s query. Your task is to analyze the provided data and user intent, then derive the most relevant overarching term that contextualizes the input.

Examples of Overarching Terms (Brands-Based)

	1.	Netflix, Amazon Prime Video, Disney+, Hulu, Apple TV+: “streaming services”
	2.	Gath, Decathlon Olaian, Pukas: “surfing hardware”
	3.	Coca-Cola, Pepsi, Dr Pepper, Sprite, Fanta: “soft drinks”
	4.	Nike, Adidas, Puma, Reebok, Under Armour: “sportswear brands”
	5.	Toyota, Ford, Tesla, BMW, Mercedes-Benz: “cars”
	6.	Microsoft, Google, Amazon, IBM, Oracle: “cloud service providers”

Examples of Overarching Terms (Products-Based)

	1.	iPhone 15, Galaxy S23, Pixel 8, OnePlus 11, Huawei P60: “smartphones”
	2.	MacBook Pro, Dell XPS 15, HP Spectre, Lenovo ThinkPad X1, ASUS ZenBook: “laptops”
	3.	PlayStation 5, Xbox Series X, Nintendo Switch OLED, Steam Deck, Meta Quest 3: “gaming consoles”
	4.	Patagonia Nano Puff, North Face ThermoBall, Arc’teryx Atom LT, Columbia Omni-Heat, Marmot Featherless: “insulated jackets”
	5.	Beats Studio Buds, Jabra Elite 7 Active, JBL Tune 230NC, Anker Soundcore Liberty 4, Sennheiser CX Plus True Wireless: “earbuds”
	6.	CamelBak Eddy+, Nalgene Wide Mouth, Hydro Flask Standard Mouth, Contigo Autoseal Chill, S’well Stainless Steel: “water bottles”

How User Queries Influence Overarching Terms

The user query provides context for the brands or products, narrowing the focus to a specific subset or characteristic. Below are examples of how this context shifts the overarching term:
	1.	Brands-Based Example
	•	Input Brands: Nike, Adidas, Puma, Reebok, Under Armour
	•	Default Term: “sportswear brands”
	•	User Query: “Which brands make the best running shoes?”
	•	Resulting Term: “running shoe brands”
	2.	Products-Based Example
	•	Input Products: iPhone 15, Galaxy S23, Pixel 8, OnePlus 11, Huawei P60
	•	Default Term: “smartphones”
	•	User Query: “What are the most affordable flagship smartphones?”
	•	Resulting Term: “affordable flagship smartphones”
	3.	Query-Specific Refinement
	•	Input Brands: Spotify, Apple Music, Tidal, YouTube Music, Deezer
	•	Default Term: “music streaming services”
	•	User Query: “Which platforms are best for audiophiles?”
	•	Resulting Term: “high-fidelity music platforms”
	4.	From General to Specific
	•	Input Brands: Tesla, Rivian, Lucid Motors, Fisker, Polestar
	•	Default Term: “electric vehicles”
	•	User Query: “What are the leading luxury electric SUVs?”
	•	Resulting Term: “luxury electric SUVs”

Instructions

	•	Step 1: Identify the initial overarching term based on the input brands or products.
	•	Step 2: Analyze the user query to determine its focus, specificity, or intent.
	•	Step 3: Refine the overarching term to align with the query’s context.
	•	Step 4: Provide the final term with clarity and relevance to the user’s request.#{' '}
    •	Step 5: Term should be 1 - 3 words, not longer, if it is, summarize it or abstract it.
EOF

        schema do
            string :name, required: true, description: "The name of the overarching term"
        end

        def perform
            res = chat(<<-PROMPT.promptize)
                    * #{entity_type.pluralize}: #{self.leaders}
                    * User query: #{report.query}
                PROMPT

            res.parsed.name
        end

        private

        def entity_type
            (topic["type"] || "brand").pluralize
        end

        def leaders
            entities = topic["type"] == "product" ? self.entities["products"] : self.entities["brands"]
            entities.map { |entity| entity["name"] }.slice(0, 10).join(", ")
        end
    end


    class TermAttributes
        include Analysis::Inference

        attr_accessor :overarching_term, :language, :provider, :model, :temperature

        system <<-EOF.promptize
            You are an AI agent specializing in identifying the most important attributes to perform competitive analysis on a set of products or brands
        EOF

        schema do
            define :attribute do
                string :name, required: true, description: "The name of the attribute"
                string :definition, required: true, description: "A definition for the attribute"
                string :why, required: true, description: "Why this attribute is important to evaluate competitors in the same category"
            end

            array :attributes, items: ref(:attribute), description: "The five most important attributes to evaluate competitors in the same category"
        end

        def perform
            res = chat(<<-PROMPT.promptize)
                What are the five most important attributes to evaluate competitors in the "#{overarching_term}" category?
            PROMPT

            res.parsed.attributes
        end
    end
end
