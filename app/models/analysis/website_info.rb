# This requires some chrome browser in the box, and we need to check
# concurrency. Maybe we can use a scraping service instead.
class Analysis::WebsiteInfo < Analysis::Step
    attribute :url, :string

    def input_is_valid
        unless self.url.present?
            self.errors.add(:url, "URL is required")
        end
    end

    def perform
        url = self.attributes["url"]

        begin
            response = fetch_with_retry(url)
        rescue => e
            self.error = e.message
            return true # save it anyway
        end

        document = Nokogiri::HTML(response.body)

        meta_tags = document.css("meta").each_with_object({}) do |meta, hash|
            name = meta.attr("name") || meta.attr("property")
            content = meta.attr("content")
            hash[name] = content if name && content
        end

        toc = document.css("h1, h2, h3").map do |heading|
                "\t" * ((heading.name[1].to_i rescue 1) -1) + "- " + heading.text
        end.join("\n")

        self.result =  { url: url, title: document.title, meta_tags: meta_tags, toc: toc }
        true
    end

    def fetch_with_retry(url)
        attempt = 1
        begin
            response = Faraday.get(url)
            unless response.success?
                raise "Failed to fetch the page #{url}"
            end
            response
        rescue => e
            if attempt < MAX_ATTEMPT_COUNT
                Rails.logger.error("Error fetching #{url}: #{e.message}. Retrying (#{attempt + 1}/#{MAX_ATTEMPT_COUNT})...")
                sleep(attempt)
                attempt += 1
                retry
            else
                Rails.logger.error("Error fetching #{url}: #{e.message}. No more retries left.")
                raise "Failed to fetch the page #{url} after #{MAX_ATTEMPT_COUNT} attempts"
            end
        end
    end

   def result_presenter
    return nil unless succeeded?
    r = result.with_indifferent_access
    ResultPresenter.new(
        url: r.dig(:url),
        title: r.dig(:title),
        description: r.dig(:meta_tags, "description") || r.dig(:meta_tags, "og:description"),
        toc: r.dig(:toc)
    )
   end
end

class ResultPresenter < Struct.new(:url, :title, :description, :toc)
    def to_h
        { url: url, title: title, description: description, toc: toc }
    end
end
