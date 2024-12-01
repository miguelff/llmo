class Result::Links
    include ChartsHelper
    attr_reader :competitors, :entities, :input

    def initialize(entities:, input:)
        @entities = entities
        @input = input
    end

    def each(&block)
        links.each(&block)
    end

    def links
        @links ||= entities["links"].map do |link, attrs|
                        attrs["hits"] = (attrs["brands"]&.length || 0) + (attrs["products"]&.length || 0) + (attrs["orphan_hits"] || 0)
                        [ link, attrs.with_indifferent_access ]
                    end.sort_by { |link| link.last[:hits] }.reverse
    end

    def domains
        @domains ||= {}.tap do |domains|
                        links.map { |domain, attrs| [ Addressable::URI.parse(domain).host, attrs[:hits] ] }.each do |domain, hits|
                            domains[domain] ||= 0
                            domains[domain] += hits
                        end
                    end
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
end
