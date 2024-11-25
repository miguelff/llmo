require "test_helper"

class Analysis::EntityExtractionTest < ActiveSupport::TestCase
  test "de" do
    answers = {
      "Welche Automarken bieten die sichersten Fahrzeuge für Frauen über 45 Jahren an?" =>  <<-TEXT.squish
      "Hier sind einige der sichersten Automarken und Modelle, die für Frauen über 45 Jahren empfohlen werden, basierend auf den neuesten Euro NCAP-Crashtests und Sicherheitsbewertungen:

        ### 1. **Volkswagen**
          - **Modell:** VW ID.7
          - **Sicherheitsbewertung:** 5 Sterne (346/400 Punkte)
          - **Begründung:** Der VW ID.7 bi
        etet hervorragenden Schutz für Insassen und Fußgänger sowie fortschrittliche Fahrassistenzsysteme, die das Unfallrisiko minimieren. Die hohe Punktzahl in den Crashtests zeigt, dass Volkswagen großen Wert auf Sicherheit legt.
          - **Quelle:** [ADAC](https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap/)

        ### 2. *
        *NIO**
          - **Modell:** NIO ET5
          - **Sicherheitsbewertung:** 5 Sterne (345/400 Punkte)
          - **Begründung:** Der NIO ET5 bietet exzellenten Insassenschutz und wirksame Notbremssysteme, die auf verschiedene Verkehrsteilnehmer reagieren. Dies macht ihn zu einer sicheren Wahl für alle Fahrer.
          - **Quelle:** [AutoScout24](https://www.autosco
        ut24.de/informieren/ratgeber/auto-sicherheit/ncap-sicherste-autos/)

        ### 3. **Smart**
          - **Modell:** Smart #3
          - **Sicherheitsbewertung:** 5 Sterne (345/400 Punkte)
          - **Begründung:** Der Smart #3 ist ein kompakter SUV mit umfangreichen Sicherheitsfeatures, die sowohl Insassen als auch Fußgänger schützen. Seine hohe Sicherheitsbewert
        ung macht ihn zu einer idealen Wahl für sicherheitsbewusste Fahrer.
          - **Quelle:** [Finn](https://www.finn.com/de-DE/auto/bestenliste/sicherstes-auto)

        ### 4. **Tesla**
          - **Modelle:** Tesla Model 3, Model Y
          - **Sicherheitsbewertung:** 5 Sterne
          - **Begründung:** Tesla-Fahrzeuge sind bekannt für ihren hohen Insassenschutz und umf
        angreiche Sicherheitsassistenzsysteme. Die Modelle bieten nicht nur Sicherheit, sondern auch innovative Technologien, die das Fahren erleichtern.
          - **Quelle:** [Carwow](https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos)

        ### 5. **Volvo**
          - **Modelle:** Volvo XC60, XC90
          - **Sicherheitsbewertung:** 5 S
        terne
          - **Begründung:** Volvo hat einen hervorragenden Ruf für Sicherheit. Die Modelle XC60 und XC90 bieten herausragenden Insassenschutz und sind mit effektiven aktiven Sicherheitssystemen ausgestattet, die das Risiko von Unfällen verringern.
          - **Quelle:** [ADAC](https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos
        -euroncap-2022/)

        ### Fazit
        Die oben genannten Modelle wurden aufgrund ihrer hohen Sicherheitsbewertungen und der Verfügbarkeit moderner Sicherheitsassistenzsysteme ausgewählt. Diese Fahrzeuge bieten nicht nur Schutz für die Insassen, sondern auch Technologien, die das Fahren sicherer und einfacher machen. Es ist wichtig, beim Autokauf auf d
        ie Euro NCAP-Bewertungen zu achten und sich mit den spezifischen Sicherheitsmerkmalen der Fahrzeuge vertraut zu machen.
    TEXT
    }

    VCR.use_cassette("analysis/entity_extraction") do
      report = Report.create!(query: "beste Autos für Frauen über 45 Jahren", brand_info: "Volkswagen Tiguan", owner: users(:jane))
      extraction = Analysis::EntityExtraction.new(answers: answers, language: "deu", report: report)
      assert extraction.valid?, extraction.errors.full_messages

      assert extraction.perform
      assert_equal(
      {
        "brands" => [
          {
            "name" => "Volkswagen",
            "links" => [
              "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap/"
            ],
            "positions" => [ 1 ],
            "products" => [ "Volkswagen VW ID.7" ]
          },
          {
            "name" => "NIO",
            "links" => [
              "https://www.autoscout24.de/informieren/ratgeber/auto-sicherheit/ncap-sicherste-autos/"
            ],
            "positions" => [ 2 ],
            "products" => [ "NIO ET5" ]
          },
          {
            "name" => "Smart",
            "links" => [
              "https://www.finn.com/de-DE/auto/bestenliste/sicherstes-auto"
            ],
            "positions" => [ 3 ],
            "products" => [ "Smart #3" ]
          },
          {
            "name" => "Tesla",
            "links" => [
              "https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos"
            ],
            "positions" => [ 4 ],
            "products" => [ "Tesla Model 3", "Tesla Model Y" ]
          },
          {
            "name" => "Volvo",
            "links" => [
              "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap-2022/"
            ],
            "positions" => [ 5 ],
            "products" => [ "Volvo XC60", "Volvo XC90" ]
          }
        ],
        "products" => [
          {
            "name" => "Volkswagen VW ID.7",
            "links" => [
              "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap/"
            ],
            "positions" => [ 1 ],
            "brand" => "Volkswagen"
          },
          {
            "name" => "NIO ET5",
            "links" => [
              "https://www.autoscout24.de/informieren/ratgeber/auto-sicherheit/ncap-sicherste-autos/"
            ],
            "positions" => [ 2 ],
            "brand" => "NIO"
          },
          {
            "name" => "Smart #3",
            "links" => [
              "https://www.finn.com/de-DE/auto/bestenliste/sicherstes-auto"
            ],
            "positions" => [ 3 ],
            "brand" => "Smart"
          },
          {
            "name" => "Tesla Model 3",
            "links" => [
              "https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos"
            ],
            "positions" => [ 4 ],
            "brand" => "Tesla"
          },
          {
            "name" => "Tesla Model Y",
            "links" => [
              "https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos"
            ],
            "positions" => [ 4 ],
            "brand" => "Tesla"
          },
          {
            "name" => "Volvo XC60",
            "links" => [
              "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap-2022/"
            ],
            "positions" => [ 5 ],
            "brand" => "Volvo"
          },
          {
            "name" => "Volvo XC90",
            "links" => [
              "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap-2022/"
            ],
            "positions" => [ 5 ],
            "brand" => "Volvo"
          }
        ],
        "links" => {
          "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap/" => {
            "product_hits" => 1,
            "brand_hits" => 1,
            "orphan_hits" => 0,
            "brands" => [ "Volkswagen" ],
            "products" => [ "Volkswagen VW ID.7" ]
          },
          "https://www.autoscout24.de/informieren/ratgeber/auto-sicherheit/ncap-sicherste-autos/" => {
            "product_hits" => 1,
            "brand_hits" => 1,
            "orphan_hits" => 0,
            "brands" => [ "NIO" ],
            "products" => [ "NIO ET5" ]
          },
          "https://www.finn.com/de-DE/auto/bestenliste/sicherstes-auto" => {
            "product_hits" => 1,
            "brand_hits" => 1,
            "orphan_hits" => 0,
            "brands" => [ "Smart" ],
            "products" => [ "Smart #3" ]
          },
          "https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos" => {
            "product_hits" => 2,
            "brand_hits" => 1,
            "orphan_hits" => 0,
            "brands" => [ "Tesla" ],
            "products" => [ "Tesla Model 3", "Tesla Model Y" ]
          },
          "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap-2022/" => {
            "product_hits" => 2,
            "brand_hits" => 1,
            "orphan_hits" => 0,
            "brands" => [ "Volvo" ],
            "products" => [ "Volvo XC60", "Volvo XC90" ]
          }
        }
      }, extraction.result)
    end
  end

  test "aggregate results" do
    entities = [
      {
        ok: {
          "entities" => [
            {
              "type" => "brand",
              "name" => "Volkswagen",
              "position" => 1,
              "links" => [
                {
                  "url" => "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap/"
                }
              ]
            },
            {
              "type" => "product",
              "name" => "Volkswagen VW ID.7",
              "position" => 1,
              "links" => [
                {
                  "url" => "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap/"
                }
              ]
            },
            {
              "type" => "brand",
              "name" => "NIO",
              "position" => 2,
              "links" => [
                {
                  "url" => "https://www.autoscout24.de/informieren/ratgeber/auto-sicherheit/ncap-sicherste-autos/"
                }
              ]
            },
            {
              "type" => "product",
              "name" => "NIO ET5",
              "position" => 2,
              "links" => [
                {
                  "url" => "https://www.autoscout24.de/informieren/ratgeber/auto-sicherheit/ncap-sicherste-autos/"
                }
              ]
            },
            {
              "type" => "brand",
              "name" => "Smart",
              "position" => 3,
              "links" => [
                {
                  "url" => "https://www.finn.com/de-DE/auto/bestenliste/sicherstes-auto"
                }
              ]
            },
            {
              "type" => "product",
              "name" => "Smart #3",
              "position" => 3,
              "links" => [
                {
                  "url" => "https://www.finn.com/de-DE/auto/bestenliste/sicherstes-auto"
                }
              ]
            },
            {
              "type" => "brand",
              "name" => "Tesla",
              "position" => 4,
              "links" => [
                {
                  "url" => "https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos"
                }
              ]
            },
            {
              "type" => "product",
              "name" => "Tesla Model 3",
              "position" => 4,
              "links" => [
                {
                  "url" => "https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos"
                }
              ]
            },
            {
              "type" => "product",
              "name" => "Tesla Model Y",
              "position" => 4,
              "links" => [
                {
                  "url" => "https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos"
                }
              ]
            },
            {
              "type" => "brand",
              "name" => "Volvo",
              "position" => 5,
              "links" => [
                {
                  "url" => "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap-2022/"
                }
              ]
            },
            {
              "type" => "product",
              "name" => "Volvo XC60",
              "position" => 5,
              "links" => [
                {
                  "url" => "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap-2022/"
                }
              ]
            },
            {
              "type" => "product",
              "name" => "Volvo XC90",
              "position" => 5,
              "links" => [
                {
                  "url" => "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap-2022/"
                }
              ]
            }
          ],
          "orphan_links" => []
        }
      },
      {
        ok: {
          "entities" => [
            {
              "type" => "brand",
              "name" => "Volkswagen",
              "position" => 2,
              "links" => [
                {
                  "url" => "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap/"
                }
              ]
            },
            {
              "type" => "product",
              "name" => "Volkswagen VW ID.7",
              "position" => 2,
              "links" => [
                {
                  "url" => "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap/"
                }
              ]
            },
            {
              "type" => "brand",
              "name" => "NIO",
              "position" => 1,
              "links" => [
                {
                  "url" => "https://www.autoscout24.de/informieren/ratgeber/auto-sicherheit/ncap-sicherste-autos/"
                }
              ]
            },
            {
              "type" => "product",
              "name" => "NIO ET5",
              "position" => 1,
              "links" => [
                {
                  "url" => "https://www.autoscout24.de/informieren/ratgeber/auto-sicherheit/ncap-sicherste-autos/"
                }
              ]
            },
            {
              "type" => "brand",
              "name" => "Smart",
              "position" => 4,
              "links" => [
                {
                  "url" => "https://www.finn.com/de-DE/auto/bestenliste/sicherstes-auto"
                }
              ]
            },
            {
              "type" => "product",
              "name" => "Smart #3",
              "position" => 4,
              "links" => [
                {
                  "url" => "https://www.finn.com/de-DE/auto/bestenliste/sicherstes-auto"
                }
              ]
            },
            {
              "type" => "brand",
              "name" => "Tesla",
              "position" => 4,
              "links" => [
                {
                  "url" => "https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos"
                }
              ]
            },
            {
              "type" => "product",
              "name" => "Tesla Model 3",
              "position" => 4,
              "links" => [
                {
                  "url" => "https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos"
                }
              ]
            },
            {
              "type" => "product",
              "name" => "Tesla Model Y",
              "position" => 4,
              "links" => [
                {
                  "url" => "https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos"
                }
              ]
            },
            {
              "type" => "brand",
              "name" => "Volvo",
              "position" => 5,
              "links" => [
                {
                  "url" => "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap-2022/"
                }
              ]
            },
            {
              "type" => "product",
              "name" => "Volvo XC60",
              "position" => 5,
              "links" => [
                {
                  "url" => "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap-2022/"
                }
              ]
            },
            {
              "type" => "product",
              "name" => "Volvo XC90",
              "position" => 5,
              "links" => [
                {
                  "url" => "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap-2022/"
                }
              ]
            }
          ],
          "orphan_links" => []
        }
      }
    ]

    aggregated = Analysis::EntityExtraction.aggregate(entities)

    assert_equal [
        {
          "name" => "Volkswagen",
          "links" => [
            "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap/",
            "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap/"
          ],
          "positions" => [ 1, 2 ],
          "products" => [
            "Volkswagen VW ID.7"
          ]
        },
        {
          "name" => "NIO",
          "links" => [
            "https://www.autoscout24.de/informieren/ratgeber/auto-sicherheit/ncap-sicherste-autos/",
            "https://www.autoscout24.de/informieren/ratgeber/auto-sicherheit/ncap-sicherste-autos/"
          ],
          "positions" => [ 2, 1 ],
          "products" => [
            "NIO ET5"
          ]
        },
        {
          "name" => "Smart",
          "links" => [
            "https://www.finn.com/de-DE/auto/bestenliste/sicherstes-auto",
            "https://www.finn.com/de-DE/auto/bestenliste/sicherstes-auto"
          ],
          "positions" => [ 3, 4 ],
          "products" => [
            "Smart #3"
          ]
        },
        {
          "name" => "Tesla",
          "links" => [
            "https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos",
            "https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos"
          ],
          "positions" => [ 4, 4 ],
          "products" => [
            "Tesla Model 3",
            "Tesla Model Y"
          ]
        },
        {
          "name" => "Volvo",
          "links" => [
            "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap-2022/",
            "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap-2022/"
          ],
          "positions" => [ 5, 5 ],
          "products" => [
            "Volvo XC60",
            "Volvo XC90"
          ]
        }
      ], aggregated["brands"]


    assert_equal [
      {
        "name" => "Volkswagen VW ID.7",
        "links" => [
          "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap/",
          "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap/"
        ],
        "positions" => [ 1, 2 ],
        "brand" => "Volkswagen"
      },
      {
        "name" => "NIO ET5",
        "links" => [
          "https://www.autoscout24.de/informieren/ratgeber/auto-sicherheit/ncap-sicherste-autos/",
          "https://www.autoscout24.de/informieren/ratgeber/auto-sicherheit/ncap-sicherste-autos/"
        ],
        "positions" => [ 2, 1 ],
        "brand" => "NIO"
      },
      {
        "name" => "Smart #3",
        "links" => [
          "https://www.finn.com/de-DE/auto/bestenliste/sicherstes-auto",
          "https://www.finn.com/de-DE/auto/bestenliste/sicherstes-auto"
        ],
        "positions" => [ 3, 4 ],
        "brand" => "Smart"
      },
      {
        "name" => "Tesla Model 3",
        "links" => [
          "https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos",
          "https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos"
        ],
        "positions" => [ 4, 4 ],
        "brand" => "Tesla"
      },
      {
        "name" => "Tesla Model Y",
        "links" => [
          "https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos",
          "https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos"
        ],
        "positions" => [ 4, 4 ],
        "brand" => "Tesla"
      },
      {
        "name" => "Volvo XC60",
        "links" => [
          "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap-2022/",
          "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap-2022/"
        ],
        "positions" => [ 5, 5 ],
        "brand" => "Volvo"
      },
      {
        "name" => "Volvo XC90",
        "links" => [
          "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap-2022/",
          "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap-2022/"
        ],
        "positions" => [ 5, 5 ],
        "brand" => "Volvo"
      }
    ], aggregated["products"]

    assert_equal(
      {
        "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap/" => {
          "product_hits" => 2,
          "brand_hits" => 2,
          "orphan_hits" => 0,
          "brands" => [ "Volkswagen" ],
          "products" => [ "Volkswagen VW ID.7" ]
        },
        "https://www.autoscout24.de/informieren/ratgeber/auto-sicherheit/ncap-sicherste-autos/" => {
          "product_hits" => 2,
          "brand_hits" => 2,
          "orphan_hits" => 0,
          "brands" => [ "NIO" ],
          "products" => [ "NIO ET5" ]
        },
        "https://www.finn.com/de-DE/auto/bestenliste/sicherstes-auto" => {
          "product_hits" => 2,
          "brand_hits" => 2,
          "orphan_hits" => 0,
          "brands" => [ "Smart" ],
          "products" => [ "Smart #3" ]
        },
        "https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos" => {
          "product_hits" => 4,
          "brand_hits" => 2,
          "orphan_hits" => 0,
          "brands" => [ "Tesla" ],
          "products" => [ "Tesla Model 3", "Tesla Model Y" ]
        },
        "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap-2022/" => {
          "product_hits" => 4,
          "brand_hits" => 2,
          "orphan_hits" => 0,
          "brands" => [ "Volvo" ],
          "products" => [ "Volvo XC60", "Volvo XC90" ]
        }
      },
      aggregated["links"]
    )
  end
end
