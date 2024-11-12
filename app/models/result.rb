class Result < ApplicationRecord
  belongs_to :report

  def presenter
    @presenter ||= Presenter.new(self)
  end

  class Presenter
    include ChartsHelper
    attr_reader :result

    def initialize(result)
      @result = result
    end

    def leaders
      series = data["leaders"]
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
                categories: series.map { |leader| leader["name"] },
                title: {
                  text: "Leaders"
                }
              }
            }
      chart(options)
    end

    private

    def data
      @data ||= JSON.parse(@result.json)["value"]
    end
  end
end
