# This requires some chrome browser in the box, and we need to check
# concurrency. Maybe we can use a scraping service instead.
class Analysis::YourWebsite < Analysis::Step
  input :url, String, valid_format: ->(url) {
                        Addressable::URI.parse(url)&.domain&.present?
                      },
                      transform: ->(url) {
                        return nil if url.blank?
                        return "http://#{url}" unless url.starts_with?("http")
                        url
                      }

  def self.empty
    self.for(url: nil)
  end

  def perform
    self.input = { url: self.url }

    begin
      response = self.class.fetch_with_retry(self.url)
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
      {
        level: heading.name[1].to_i,
        text: heading.text
      }
    end

    self.result = { url: self.url, title: document.title, meta_tags: meta_tags, toc: toc }
    true
  end

  def self.fetch_with_retry(url)
    attempt = 1
    begin
      response = Faraday.get(url)
      raise "Failed to fetch the page #{url}" unless response.success?

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

  def presenter
    return nil unless succeeded?
    Analysis::Presenters::Website.from_json(result)
  end
end
