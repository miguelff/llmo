class Analysis::QuestionAnswering < ApplicationRecord
    class BingSearch
        extend Langchain::ToolDefinition

        define_function :search, description: "Executes Bing Search and returns the result" do
            property :query, type: "string", description: "Search query", required: true
            property :count, type: "integer", description: "The number of results to return", required: true
        end

        def initialize(analysis)
            @analysis = analysis
        end

        def search(query:, count: 10)
            Rails.logger.info({ message: "Searching for #{query} with count #{count}" })

            market = @analysis.report.country_code || Analysis::TWO_LETTER_CODE[@analysis.language.to_sym]
            results = Bing::Search.web_results(query: query, count: count, mkt: market).download

            Concurrent::Promises.zip_futures_over(results) do |result|
                summary = <<~SUMMARY.squish
                    Search result:
                        url: #{result["url"]}
                        snippet: #{result[:html].present? ? summarize(result[:html]) : result["snippet"]}
                SUMMARY
            end.value!.join("\n\n")
        end

        def summarize(text)
            Rails.logger.info({ message: "Summarizing text", metadata: { text: text.truncate_words(10) } })
            res = OpenAI::Client.new.chat(parameters: {
                model: "gpt-4o-mini",
                messages: [
                    { role: "user", content: <<-CONTENT.squish }
                        summarize the following web page text written in #{Analysis::LANGUAGE_NAMES_IN_ENGLISH[@analysis.language.to_sym]} while focusing on capturing information relevant to make recommendations about "#{@analysis.report.query}":
                        #{' '}
                        #{text}
                    CONTENT
                ]
            })
            summary = res.dig("choices", 0, "message", "content")
            Rails.logger.info({ message: "Summarized text", metadata: { summary: summary } })
            summary
        end
    end

    include Analysis::InferenceStep

    attribute :questions, :json, default: []
    belongs_to :report, optional: false
    validates :questions, length: { minimum: 1 }

    def perform
        # Create a future for each question

        future = Concurrent::Promises.zip_futures_over(self.questions) do |question|
            begin
                question = question.with_indifferent_access[:question]
                res = assist(expand(question), tools: [ BingSearch.new(self) ])
                answer = res.last.content

                if answer.blank?
                    Rails.logger.warn({ message: "No answer for question", metadata: { question: question, response: res } })
                    { question: question, answer: nil }
                else
                    { question: question, answer: answer }
                end
            rescue => e
                { question: question, answer: nil, error: e.message }
            end
        end

        # Collect results, handling any execution errors
        self.answers = future.value!.map do |result|
            if result.is_a?(Hash) && result[:error]
                Rails.logger.error({ message: "Error in result", metadata: { error: result[:error] } })
            end
            result
        end

        true
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
