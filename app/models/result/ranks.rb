class Result::Ranks
    include Result::YourDetails
    include ChartsHelper

    def initialize(ranking, input)
      @ranking = ranking
      @input = input
    end

    def any_chart_present?
        (brand_chart || product_chart || other_products_chart).present?
    end

    def brand_chart
        chart(brand_score, "Your brand score") if brand_score
    end

    def product_chart
        chart(product_score, "Your product score") if product_score
    end

    def other_products_chart
        chart(other_product_score, "Your other products score") if other_product_score
    end

    def chart(score, label)
        options = {
            chart: {
                height: 350,
                type: "radialBar"
            },
            series: [ score ],
            labels: [ label ]
        }
        super(options)
    end
end
