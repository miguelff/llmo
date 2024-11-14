class Result < ApplicationRecord
  belongs_to :report

  def presenter
    @presenter ||= Presenter.new(self)
  end

  class Presenter
    class BrandHealth
      def initialize(health)
        @health = health
      end

      def indicator
        @health["health"].to_sym
      end

      def remarks
        @health["remarks"]
      end

      def citations
        @health["citations"]
      end

      def rank?
        rank.present?
      end

      def rank
        @health["rank"]
      end

      def score?
        score.present?
      end

      def score
        @health["score"]
      end
    end

    class BrandsAndLinks
      def initialize(brands_and_links)
        @brands_and_links = brands_and_links
      end

      def domain_breakdown?
        domain_breakdown.present?
      end


      def domain_breakdown
        @domain_breakdown ||= begin
          res = {}
          urls.each do |root, urls|
            domain = root.split(".").last(2).join(".")
            res[domain] ||= 0
            res[domain] += urls.size
          end
          res.sort_by { |domain, count| -count }
        end
      end

      def relevant_content?
        relevant_content.present?
      end

      def relevant_content
        @relevant_content ||= begin
          url_data
        end
      end

      # {
      #   "www.autobild.es" => [
      #     "https://www.autobild.es/noticias/diez-mejores-coches-familiares-comprar-2023-1233944"
      #   ],
      #   "www.20minutos.es" => [
      #     "https://www.20minutos.es/motor/coches/byd-unica-marca-3-coches-top-10-familiares-mas-seguros-2023-euro-ncap-electrico-5197859/"
      #   ]
      # }
      def urls
        @brands_and_links["urls"]
      end


      def url_data
        url_data = {}

        @brands_and_links["topics"].each do |topic|
          name = topic["name"]
          urls = topic["urls"]

          urls.each do |url|
            uri = Addressable::URI.parse(url)
            domain = uri.host
            path = uri.path

            url_data[url] ||= { domain: domain, path: path, count: 0, names: [] }
            url_data[url][:count] += 1
            url_data[url][:names] << name unless url_data[url][:names].include?(name)
          end
        end

        url_data.sort { |x, y| y.last[:count] - x.last[:count] }.slice(0, 10)
      end
    end

    include ChartsHelper
    attr_reader :result

    def initialize(result)
      @result = result
    end

    def leaders_chart
      series = data["leaders"]["leaders"].slice(0, 10)
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

    def domain_breakdown_chart
      options = {
        chart: {
          type: "treemap",
          height: 400,
          toolbar: {
            show: false
          }
        },
        dataLabels: {
          style: {
            fontSize: "16px"
          }
        },
        series: [
          {
            data: domains.map { |domain, count| { x: domain, y: count } }
          }
        ]
      }
      chart(options)
    end

    def relevant_content?
      brands_and_links.present? && brands_and_links.relevant_content?
    end

    def relevant_content
      @relevant_content ||= (brands_and_links.relevant_content if relevant_content?)
    end

    def brand_health?
      data["brandHealth"].present?
    end

    def brand_health
      @brand_health ||= (BrandHealth.new(data["brandHealth"]["brands"].first) if brand_health?)
    end

    def perception?
      perception.present?
    end

    def perception
      @perception ||= (brand_health.citations if brand_health.present? && brand_health.citations.present?)
    end

    def domains?
      domains.present?
    end

    def domains
      @domains ||= (brands_and_links.domain_breakdown if brands_and_links? && brands_and_links.domain_breakdown?)
    end

    def brands_and_links?
      brands_and_links.present?
    end

    def brands_and_links
      @brands_and_links ||= BrandsAndLinks.new(data["brandsAndLinks"])
    end

    def key_phrases
      series = data["keyPhrases"]
      options = {
        chart: {
          type: "table"
        }...
      }
    end

    private

    def data
      @data ||= JSON.parse(@result.json)["value"]
    end
  end
end
