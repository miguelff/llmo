require "faraday"

Faraday::Connection.prepend(
  Module.new do
    def run_request(method, url, *args)
      # Calcualte cost based on domain:
      # * api.bing.microsoft.com is 2,
      # * api.openai.com is 8,
      # * Rest is 1
      cost = case Addressable::URI.parse(url).host
      when "api.bing.microsoft.com"
               Analysis::Step::COSTS[:search]
      when "api.openai.com"
               Analysis::Step::COSTS[:inference]
      else
               Analysis::Step::COSTS[:download]
      end
      ActiveSupport::Notifications.instrument("expensive_operation", method: method, url: url, cost: cost, args: args) { super }
    end
  end
)
