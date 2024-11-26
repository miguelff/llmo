ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

VCR.configure do |config|
  config.cassette_library_dir = "test/vcr"
  config.hook_into :webmock
  config.filter_sensitive_data("<API_KEY>") { Rails.application.credentials.processor[:OPENAI_API_KEY] }
  config.allow_http_connections_when_no_cassette = true
  config.default_cassette_options = { record: ENV["VCR_RECORD_MODE"]&.to_sym || :none }
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
