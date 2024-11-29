class Result::ProductStrengths
include ChartsHelper

  def initialize(competitors:, entities:)
    @competitors = competitors
    @entities = entities
  end

  def overarching_term
    @competitors["overarching_term"]
  end

  def attributes
    @competitors["term_attributes"].map { |attr| { name: attr["name"], definition: attr["definition"] } }
  end

  def chart
    @chart ||= begin
        labels = @competitors["term_attributes"].map { |attr| attr["name"] }
        series = @competitors["competition_scores"].map do |scores|
            data = labels.map do |label|
            score_text = scores["scores"].find { |score| score["attribute"].downcase.strip == label.downcase.strip }["score"] || "0/10"
            score_text.split("/").first.to_i rescue 0
            end
            { name: scores["name"], data: data }
        end

        series = scale(series)

        options = {
            chart: {
                type: "radar"
            },
            series: series,
            labels: labels,
              xaxis: {
                labels: {
                  style: {
                    fontSize: "12pt"
                  }
                }
              },
              yaxis: {
                labels: {
                  style: {
                    fontSize: "2pt"
                  }
                }
              },
              dataLabels: {
                enabled: true,
                style: {
                  fontSize: "12pt",
                  fontWeight: "bold"
                }
              },
              legend: {
                fontSize: "12pt"
              }
        }
        super(options)
    rescue => e
        Rails.logger.error("Error generating product strengths chart: #{e.message}, Competitors: #{@competitors.inspect}")
        nil
    end
  end
end

def scale(series)
    series.each do |s|
        s[:data] = s[:data].map { |d| d / 2.0 }
    end
    series
end
