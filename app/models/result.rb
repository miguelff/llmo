class Result
  attr_reader :report

  def initialize(report)
    @report = report
  end

  # def domain_breakdown_chart
  #   options = {
  #     chart: {
  #       type: "treemap",
  #       height: 400,
  #       toolbar: {
  #         show: false
  #       }
  #     },
  #     dataLabels: {
  #       style: {
  #         fontSize: "16px"
  #       }
  #     },
  #     series: [
  #       {
  #         data: domains.map { |domain, count| { x: domain, y: count } }
  #       }
  #     ]
  #   }
  #   chart(options)
  # end

  # def relevant_content?
  #   brands_and_links.present? && brands_and_links.relevant_content?
  # end

  # def relevant_content
  #   @relevant_content ||= (brands_and_links.relevant_content if relevant_content?)
  # end

  def product_strengths?
    product_strengths.present?
  end

  def product_strengths
    @product_strengths ||= Result::ProductStrengths.new(competitors: competitors_analysis.result, entities: entities_analysis.result, input: input_classifier_analysis.result)
  end

  def leaders?(group)
    ranking_analysis.present? &&
    leaders(group).present?
  end

  def leaders(group)
    @leaders ||= {}
    @leaders[group] ||= Result::Leaders.new(group: group, ranking: ranking_analysis.result)
  end

  def brand_health
    @brand_health ||= Result::BrandHealth.new(ranking: ranking_analysis.result, entities: entities_analysis.result, input: input_classifier_analysis.result)
  end

  def ranks
    @ranks ||= Result::Ranks.new(ranking: ranking_analysis.result, entities: entities_analysis.result, input: input_classifier_analysis.result)
  end

  def analyses
    @analyses ||= report.analyses
  end

  def entities_analysis
    @entities_analysis ||= analyses.find { |analysis| analysis.type == "Analysis::EntityExtractor" }
  end

  def ranking_analysis
    @ranking_analysis ||= analyses.find { |analysis| analysis.type == "Analysis::Ranking" }
  end

  def competitors_analysis
    @competitors_analysis ||= analyses.find { |analysis| analysis.type == "Analysis::Competitors" }
  end

  def input_classifier_analysis
    @input_classifier_analysis ||= analyses.find { |analysis| analysis.type == "Analysis::InputClassifier" }
  end

  # def perception?
  #   perception.present?
  # end

  # def perception
  #   @perception ||= (brand_health.citations if brand_health.present? && brand_health.citations.present?)
  # end

  # def domains?
  #   domains.present?
  # end

  # def domains
  #   @domains ||= (brands_and_links.domain_breakdown if brands_and_links? && brands_and_links.domain_breakdown?)
  # end

  # def brands_and_links?
  #   brands_and_links.present?
  # end

  # def brands_and_links
  #   @brands_and_links ||= BrandsAndLinks.new(data["brandsAndLinks"])
  # end

  # def key_phrases
  #   series = data["keyPhrases"]
  #   options = {
  #     chart: {
  #       type: "table"
  #     }...
  #   }
  # end

  # private

  # def data
  #   @data ||= JSON.parse(@result.json)["value"]
  # end
end
