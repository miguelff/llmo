module Analysis::Helpers
    extend ActiveSupport::Concern
    def topic_name(topic)
        name = if topic["type"] == "product"
            name = topic["product"]
            name = "#{topic["brand"]} #{name}" if topic["brand"].present? && !name.include?(topic["brand"])
            name
        else
            topic["brand"]
        end

        name.strip
    end
end
