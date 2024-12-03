class Analysis::QuestionAnswering < Analysis::Step
    class BingSearch
        extend Langchain::ToolDefinition

        define_function :search, description: "Executes Bing Search and returns the result" do
            property :query, type: "string", description: "Search query", required: true
            property :count, type: "integer", description: "The number of results to return", required: true
        end

        def initialize(analysis)
            @analysis = analysis
        end

        def search(query:, count: 5)
            Rails.logger.info({ message: "Searching for #{query} with count #{count}" })

            market = @analysis.report.country_code || Analysis::TWO_LETTER_CODE[@analysis.language.to_sym]
            results = Bing::Search.web_results(query: query, count: count, mkt: market).download

            Concurrent::Promises.zip_futures_over(results) do |result|
                {
                    "URL": result["url"],
                    "Snippet": (result[:html].present? ? summarize(result[:html]) : result["snippet"])
                }
            end.value!.to_json
        end

        def summarize(text)
            Rails.logger.info({ message: "Summarizing text", metadata: { text: text.truncate_words(10) } })
            res = OpenAI::Client.new.chat(parameters: {
                model: "gpt-4o-mini",
                messages: [
                    { role: "user", content: <<-CONTENT.promptize }
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

    include Analysis::Inference

    attr_accessor :callback
    attribute :questions, :json, default: []
    validates :questions, length: { minimum: 1 }

    def perform
        answers = Concurrent::Promises.zip_futures_over(self.questions) do |question|
            begin
                res = assist(expand(question), tools: [ BingSearch.new(self) ], model: "gpt-4o", temperature: 0.5)
                answer = res.last.content

                self.callback&.call(question, answer)

                if answer.blank?
                    Rails.logger.warn({ message: "No answer for question", metadata: { question: question, response: res } })
                    { question: question, answer: nil }
                else
                    { question: question, answer: answer }
                end
            rescue => e
                Rails.logger.error({ message: "Error in result", metadata: { question: question, error: e.message } })
                { question: question, answer: nil, error: e.message }
            end
        end.value!

        correct_answers, nil_answers = answers.partition { |a| a[:answer].present? }
        if nil_answers.length > correct_answers.length
            err = "Not enough answers: #{nil_answers.length} nil answers and #{correct_answers.length} correct answers."
            sample_error = nil_answers.find { |a| a[:error].present? }
            err += " Sample error: #{sample_error[:error]}" if sample_error
            self.error =  err
            false
        else
            self.result = correct_answers
            true
        end
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
