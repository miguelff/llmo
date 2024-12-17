class Analysis::Tools::BingSearch
    extend Langchain::ToolDefinition

    define_function :search, description: "Search in Bing for relevant results to provide reliable information for the question" do
        property :query, type: "string", description: "The search query", required: true
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