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
            string :type, enum: %w[brand product service other], description: "The type of the entity, it's a commercial name associated to either a brand, product or service"
            string :name, description: "The name of the entity, like 'Apple' or 'Adidas Ultraboost 22' or 'Netflix'"
            number :position, description: "The position of the entity in the answer, the first entity appearing in the text is 1, the second 2, and so on"
            array :links, items: ref(:link), description: "Links related to the entity, used to include the entity in the particular answer to the given question"
        end

        array :entities, items: ref(:entity), description: "Entities found in the report's query"
        array :orphan_links, items: ref(:link), description: "Links that were not related to any particular entity"
    end

    STEP_1_SYSTEM = {
        eng: <<-EOF.squish
            You are an assistant specialized in entity extraction.

            You are given a user query, and a response from an AI assistant about the user query comparing several brands, products or services related to the query.

            Your task is to extract:
            1. all the entities mentioned in the query and response that are commercial names associated to either a brand, product or service, including:
                1.1 The type of the entity, it's a commercial name associated to either a brand, product or service
                1.2 The name of the entity, like 'Apple' or 'Adidas Ultraboost 22' or 'Netflix'
                1.3 The position of the entity in the answer, the first entity appearing in the text is 1, the second 2, and so on.
                1.4 Any link related to the entity, that seems to be a source of information to include the entity in the particular answer to the given question
            2. A list of other links that are present in the text, but not related to any particular entity, called "orphan links"

            Return as many entities and links as you can find in the given text.
        EOF
    }

    def perform
        self.result =self.answers.map do |q, a|
            step1_system_prompt = STEP_1_SYSTEM[self.language.to_sym] || STEP_1_SYSTEM[Analysis::DEFAULT_LANGUAGE]
            messages = [ { role: :system, content: step1_system_prompt }, { role: :user, content: user_prompt(answer) } ]

            parameters = self.parameters(messages)
            parameters[:response_format] = STEP_1_SCHEMA

            client.parse(**parameters)
        end

        true
    end


    def user_prompt(answer)
        <<-EOF.squish
            User query: #{self.report.query}
            AI assistant response: #{answer}
        EOF
    end
end
