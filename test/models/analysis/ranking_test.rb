require "test_helper"

class Analysis::RankingTest < ActiveSupport::TestCase
    def analysis(entities:, input: {}, query: "items")
        Analysis::Ranking.new(entities: entities, input: input, report: Report.new(query: query, owner: users(:jane)))
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
        analysis = analysis(entities: WATCHES, input: { "type" => "product", "brand" => "omega", "product" => "seamaster diver 300m" })
            assert analysis.perform_and_save
            assert_equal(
            { "brands"=>[ { "name"=>"Rolex", "score"=>100.0, "rank"=>1 }, { "name"=>"Omega", "score"=>83.33, "rank"=>2 }, { "name"=>"Patek Philippe", "score"=>76.67, "rank"=>3 }, { "name"=>"Audemars Piguet", "score"=>65.0, "rank"=>4 }, { "name"=>"Tag Heuer", "score"=>62.0, "rank"=>5 } ], "products"=>[ { "name"=>"Rolex Submariner", "score"=>100.0, "rank"=>1 }, { "name"=>"Patek Philippe Nautilus", "score"=>83.33, "rank"=>2 }, { "name"=>"Omega Seamaster", "score"=>76.67, "rank"=>3 }, { "name"=>"Audemars Piguet Royal Oak", "score"=>65.0, "rank"=>4 }, { "name"=>"Tag Heuer Carrera", "score"=>62.0, "rank"=>5 } ], "you"=>{ "product_rank"=>3, "other_product_rank"=>1, "brand_rank"=>2, "reason"=>"The Omega Seamaster Diver 300M is ranked 3rd among products, while the brand Omega is ranked 2nd overall. The Seamaster is a well-known model, but it does not surpass the top-ranked Rolex Submariner." } },
              analysis.reload.result
            )
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
