class Result::Leaders
    VALID_GROUPS = %w[products brands]
    include ChartsHelper

    def initialize(ranking:, group:)
      raise "Invalid group" unless VALID_GROUPS.include?(group)
      @ranking = ranking
      @group = group
    end

    def rank
        @ranking[@group]
    end

    def leaders_chart
    series = rank.slice(0, 10)
    options = {
            chart: {
              type: "bar",
              height: 400,
              toolbar: {
                show: false
              },
              foreColor: "#fff"
            },
            plotOptions: {
              bar: {
                horizontal: true
              }
            },
            series: [
              {
                name: "Relevance",
                data: series.map { |leader| leader["score"] }
              }
            ],
            xaxis: {
                categories: series.map { |leader| leader["name"] }
            }
          }
    chart(options)
  end

  def present?
    rank.present?
  end
end
