class Analysis::QuestionAnswering < ApplicationRecord
    include Analysis::InferenceStep

    attribute :questions, :json, default: []
    belongs_to :report, optional: false
    validates :questions, length: { minimum: 1 }

    tools do
       [
        {
          type: "function",
          function: {
            name: "search",
            description: "Search in Bing for relevant results to provide reliable information for the question",
            parameters: {  # Format: https://json-schema.org/understanding-json-schema
              type: :object,
              properties: {
                query: {
                  type: :string,
                  description: "The search query"
                },
                count: {
                  type: "integer",
                  description: "The number of results to return"
                }
              },
              required: [ "query", "count" ]
            }
          }
        }
      ]
    end

    def perform
        self.answers = self.questions.map do |question|
            question = question.with_indifferent_access[:question]
            res = chat(expand(question))
            answer = res.dig("choices", 0, "message", "content")

            if answer.blank?
                Rails.logger.warn({ message: "No answer for question", metadata: { question: question, response: res } })
                { question: question, answer: nil }
            else
                { question: question, answer: answer }
            end
        end

        true
    end

    def search(query:, count: 10)
       "Searching for #{query} with count #{count}"
    end

    def expand(question)
        instructions = case self.language.to_sym
        when :spa
            "Dame marcas, y modelos de productos y/o servicios y porqué has elegido esos y no otros. Usa la herramienta de búsqueda para obtener información y respaldar resultados. Incluye URLs de los sitios consultados o webs especializadas, no incluyas fuentes que sean las oficiales de la propia marca, producto, servicio citado"
        when :deu
            "Geben Sie Marken und Modelle von Produkten und/oder Dienstleistungen an und erklären Sie, warum Sie diese und nicht andere gewählt haben. Verwenden Sie das Suchwerkzeug, um Informationen zu erhalten und Ergebnisse zu untermauern. Fügen Sie URLs der konsultierten Websites oder spezialisierten Webseiten hinzu, schließen Sie keine Quellen ein, die offizielle Seiten der genannten Marke, des Produkts oder der Dienstleistung sind."
        when :fra
            "Retournez des marques et des modèles de produits et/ou de services et expliquez pourquoi vous avez choisi ceux-ci et pas d'autres. Utilisez l'outil de recherche pour obtenir des informations et étayer les résultats. Incluez les URLs des sites consultés ou des sites spécialisés, n'incluez pas les sources officielles de la marque, du produit ou du service mentionné."
        else
            "Return brands and models of products and/or services and explain why you chose those and not others. Use the search tool to obtain information and support results. Include URLs of the consulted sites or specialized websites, do not include sources that are the official sites of the mentioned brand, product, or service."
        end

        [ question, instructions ].join(". ")
    end
end
