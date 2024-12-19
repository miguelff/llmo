class Analysis::YourBrand < Analysis::Step
    include Analysis::Inference

    input :website_info, Analysis::Presenters::Website

    def perform
        basic_info = basic_brand_info
        Rails.logger.info("Basic info: #{basic_info.inspect}")
        competitors = competitors_from_basic_info(basic_info)
        Rails.logger.info("Competitors: #{competitors.inspect}")
        brand_info = basic_info.with_competitors(competitors[:competitors])

        self.result = brand_info.to_h
        true
    end

    def presenter
        return nil unless self.succeeded?
        Analysis::Presenters::Brand.from_json(self.result)
    end

    def basic_brand_info
        instructions = <<~INSTRUCTIONS.promptize
            Extract structured information about a brand from a given website. Analyze the content and fill out the following details in the specified format:
            - Brand Name: The official name of the brand, company, or service that the website belongs to.
            - Category: The product or service category the brand offers (e.g., fashion, software, food & beverages, etc.).
            - Description: A short summary of what the brand does and its key focus areas. If the website details do not include information about a region where the brand operates most specifically, omit it.
            - Region: The geographical region where the brand operates primarily or where its main competitors are located.
            - Keywords: A list of SEO keywords, to reach the website. Low volume and high difficulty keywords are preferred. Include regional words in each keyword

            Use the search tool to find more information about the brand if you cannot extract information from the website alone
        INSTRUCTIONS


        output_schema = schema do
            define :keyword do
                string :value, description: "A keyword"
            end

            string :name, description: "The name of the brand, company, or service that the website belongs to"
            string :category, description: "The category of the product or service that the brand offers"
            string :description, description: "A short description of what they do. It should be a single sentence and might, might not be the actual description coming from the website, but something that is accurate with what the brand does"
            string :region, description: "The geopgrahical region where the brand operates and has most of its competitors"
            array :keywords, items: ref(:keyword), description: "A list of SEO keywords to reach the website"
        end

        tools = [ Analysis::Tools::BingSearch.new(self) ]

        user_message = <<-USRMSG.promptize
            The website info is:#{' '}

            #{self.website_info.to_prompt}

            Extract brand information
        USRMSG

        answer = assist(user_message, instructions: instructions, model: "gpt-4o-mini", temperature: 0, tools: tools, schema: output_schema)

        res = if answer.blank?
           Rails.logger.warn({ message: "No answer", metadata: { user_message: user_message, response: res } })
           {
            name: nil,
            category: nil,
            description: nil,
            region: nil,
            keywords: []
           }
        else
           answer
        end

        Analysis::Presenters::BrandBasicInfo.new(**res)
    end


    def competitors_from_basic_info(basic_info)
     unless basic_info.present? && basic_info.keywords.any?
         return { competitors: [] }
     end

     user_message = <<-USRMSG.promptize
            What are the main competitors of the brand #{basic_info.name}?
            The brand belongs to the following product or service category: #{basic_info.category}.
            The brand's website appears when using the following search queries in Bing:

            * #{basic_info.keywords.join("\n * ")}

            And maybe competitors are found when using similar search queries.

            Be mindful to not hallucinate competitors.
            For each competitor, provide the name of the competitor and the URL of a its website, only official websites are accepted. Comparators, blogs, news sites, that mention the brand are not accepted
            Be sure to not include the own brand being analyzed in the list of competitors

            Use the given search tool if needed.
        USRMSG

     output_schema = schema do
         define :competitor do
             string :name, description: "The name of the competitor"
             string :url, description: "The URL of the competitor's website"
         end
         array :competitors, items: ref(:competitor), description: "A list of competitors"
     end

     answer = assist(user_message, model: "gpt-4o", temperature: 0, tools: [ Analysis::Tools::BingSearch.new(self) ], schema: output_schema)

     res = if answer.blank?
        Rails.logger.warn({ message: "No answer", metadata: { user_message: user_message, response: res } })
        {
         competitors: []
        }
     else
        answer
     end

     res.with_indifferent_access
    end
end
