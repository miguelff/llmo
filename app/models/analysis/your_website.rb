# This requires some chrome browser in the box, and we need to check
# concurrency. Maybe we can use a scraping service instead.
class Analysis::YourWebsite < Analysis::Step
  class Form
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations

    attribute :url, :string

    validates :url, presence: true
    validate :valid_domain

    def valid_domain
      unless Addressable::URI.parse(transform(url))&.domain&.present?
        errors.add(:url, "doesn't have a valid format")
      end
    end

    def model(analysis:)
      if valid?
        Analysis::YourWebsite.new(analysis: analysis, input: transform(url))
      else
        nil
      end
    end

    private

    def transform(url)
      return nil if url.blank?
      return "https://#{url}" unless url.starts_with?("http")
      url
    end
  end

  class Result < ActiveRecord::Type::Value
    STRUCT = Struct.new(:url, :title, :toc, :meta_tags)

    def type
      :jsonb
    end

    def cast(value)
      if value.is_a?(Hash)
        value = value.with_indifferent_access
        STRUCT.new(*value.values_at(:url, :title, :toc, :meta_tags))
      else
        super
      end
    end

    def deserialize(value)
      return nil unless value.present?
      cast(ActiveSupport::JSON.decode(value))
    end

    def serialize(value)
      return value unless value.is_a?(STRUCT)
      ActiveSupport::JSON.encode(value.to_h)
    end
  end

  attribute :result, Result.new

  def url
    self.input
  end

  def perform
    begin
      response = fetch_with_retry
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

  def fetch_with_retry
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
    Result.from_json(result)
  end
end
