class Result::ProductStrengths
  include ChartsHelper
  include Analysis::Helpers

  def initialize(competitors:, entities:, input:)
    @competitors = competitors
    @entities = entities
    @input = input
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
        my_name = topic_name(@input)

        my_series, other_series = series.partition { |s| s[:name] == my_name }
        my_series.each { |s| s[:name] = "You" }
        series = my_series + other_series
        series.reverse!

        series = scale(series)

        options = {
            chart: {
                type: "radar"
            },
            colors: [ "#39ff14", "#a855f7", "#d946ef", "#c026d3", "#9333ea", "#7e22ce", "#6b21a8", "#581c87", "#4c1d95", "#3b0764", "#2d0f4a" ],
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
