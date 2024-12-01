require "test_helper"

class Analysis::RankingTest < ActiveSupport::TestCase
    def analysis(entities:, input: {}, query: "best watches", brand_info: "")
        Analysis::Ranking.new(entities: entities, report: Report.new(query: query, brand_info: brand_info, owner: users(:jane)))
    end

    WATCHES = {
        "products" => [
            { "name" => "Rolex Submariner", "positions" => [ 1, 2, 1 ] },
            { "name" => "Omega Seamaster", "positions" => [ 2, 3, 2 ] },
            { "name" => "Patek Philippe Nautilus", "positions" => [ 3, 1, 3 ] },
            { "name" => "Audemars Piguet Royal Oak", "positions" => [ 4, 4, 4 ] },
            { "name" => "Tag Heuer Carrera", "positions" => [ 5, 5, 5 ] }
        ],
        "brands" => [
            { "name" => "Rolex", "positions" => [ 1, 2, 1 ] },
            { "name" => "Omega", "positions" => [ 3, 1, 3 ] },
            { "name" => "Patek Philippe", "positions" => [ 2, 3, 2 ] },
            { "name" => "Audemars Piguet", "positions" => [ 4, 4, 4 ] },
            { "name" => "Tag Heuer", "positions" => [ 5, 5, 5 ] }
        ]
    }

    test "perform smoke test" do
        VCR.use_cassette("analysis/ranking/perform_smoke_test") do
            analysis = analysis(entities: WATCHES, brand_info: "omega seamaster diver 300m")
            assert analysis.perform_and_save
            you = analysis.reload.result["you"]
            assert_equal 3, you["product_rank"]
            assert_nil you["other_products_rank"]
            assert_equal 2, you["brand_rank"]
        end
    end

    test "brand is not there" do
        VCR.use_cassette("analysis/ranking/brand_not_there") do
            analysis = analysis(entities: WATCHES, brand_info: "casio g-shock")
            assert analysis.perform_and_save
            you = analysis.reload.result["you"]
            assert_nil you["brand_rank"]
            assert_nil you["other_products_rank"]
            assert_nil you["product_rank"]
        end
    end

    test "other products there" do
        VCR.use_cassette("analysis/ranking/other_products_there") do
            analysis = analysis(entities: WATCHES, brand_info: "patek philippe calatrava")
            assert analysis.perform_and_save
            you = analysis.reload.result["you"]
            assert_equal 3, you["brand_rank"]
            assert_equal 2, you["other_products_rank"]
            assert_nil you["product_rank"]
        end
    end


    test "ranking" do
        expected_ranking = [
            { name: "Item2", score: 100.0, rank: 1 },
            { name: "Item1", score: 86.67, rank: 2 },
            { name: "Item5", score: 80.0, rank: 3 },
            { name: "Item4", score: 80.0, rank: 4 },
            { name: "Item3", score: 66.67, rank: 5 },
            { name: "Item6", score: 60.0, rank: 6 },
            { name: "Item7", score: 56.67, rank: 7 },
            { name: "Item8", score: 56.67, rank: 8 }
        ]

        items = [
            { "name": "Item1", "positions": [ 2, 3, 1 ] },
            { "name": "Item2", "positions": [ 1, 1, 2 ] },
            { "name": "Item3", "positions": [ 2, 3 ] },
            { "name": "Item4", "positions": [ 2, 1 ] },
            { "name": "Item5", "positions": [ 1, 2 ] },
            { "name": "Item6", "positions": [ 2 ] },
            { "name": "Item7", "positions": [ 3 ] },
            { "name": "Item8", "positions": [ 3 ] }
        ]

        assert_equal expected_ranking, analysis(entities: { "products" => items }).products_ranking
        assert_equal [], analysis(entities: { "products" => items }).brands_ranking

        assert_equal [], analysis(entities: { "brands" => items }).products_ranking
        assert_equal expected_ranking, analysis(entities: { "brands" => items }).brands_ranking
    end
end
