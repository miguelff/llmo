require "test_helper"

class Bing::SearchTest < ActiveSupport::TestCase
    test "searching" do
        VCR.use_cassette("bing/search") do
            results = Bing::Search.web_results(query: "safe cars for women over 45", count: 4, mkt: "de")
            assert_equal 4, results.count

            list = results.list
            assert_equal 4, list.length

            first_result = list.first
            assert first_result[:title].present?, "Title should be present"
            assert first_result[:url].present?, "URL should be present"
            assert first_result[:snippet].present?, "Snippet should be present"
        end
    end

    test "downloading search results" do
        VCR.use_cassette("bing/download") do
            results = Bing::Search.web_results(query: "mejores coches de segunda mano en españa", count: 2, mkt: "en")
            downloaded = results.download
            assert_equal 2, downloaded.count
            assert downloaded.first[:html].include?("coche"), "html should contain the query"
        end
    end
end
