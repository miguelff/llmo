require "test_helper"

class Analysis::EntityExtractorTest < ActiveSupport::TestCase
  test "eng" do
    answers = { "What are the top laptops recommended for software engineering students currently available in the market?" => <<-TEXT.squish,
        Based on the analysis from various sources, here are some of the best laptop models for software development tasks in 2023, along with explanations for their selection:\n\n1. **Apple MacBook Pro 14-inch (2023)**:\n   - **Why**: Known for its M2 Pro/Max chips, this laptop offers top-tier performance, excellent battery life (nearly 20 hours), and a great display. It's ideal for complex workloads and can run both macOS and Windows.\n   - **Source**: [TechRadar](https://www.techradar.com/news/best-laptop-for-programming)\n\n2. **Dell XPS 15 (2023)**:\n   - **Why**: Offers powerful 13th Gen Intel CPUs, a stunning 3.5K OLED display, and upgradeable RAM and storage, making it versatile for different development environments including Linux.\n   - **Source**: [XDA Developers](https://www.xda-developers.com/best-laptops-programming/)\n\n3. **Lenovo ThinkPad X1 Carbon Gen 9**:\n   - **Why**: Known for its comfortable keyboard and durability, it features a Core i7 processor and 16GB of RAM, making it a great choice for business professionals who code.\n   - **Source**: [PCWorld](https://www.pcworld.com/article/705488/best-laptops-for-programming.html)\n\n4. **Asus VivoBook Pro 16X OLED**:\n   - **Why**: Features a powerful Ryzen 9 5900HX processor and a stunning 4K OLED display, ideal for intensive programming tasks.\n   - **Source**: [PCWorld](https://www.pcworld.com/article/705488/best-laptops-for-programming.html)\n\n5. **Apple MacBook Air M2**:\n   - **Why**: Lightweight with excellent battery life and a high-resolution display, it's a great value option for those needing portability and solid performance.\n   - **Source**: [XDA Developers](https://www.xda-developers.com/best-laptops-programming/)\n\n6. **Lenovo ThinkPad P1 Gen 7 (2024)**:\n   - **Why**: Offers powerful Intel CPUs and an excellent user experience, suitable for multi-monitor setups and demanding tasks.\n   - **Source**: [RTINGS](https://www.rtings.com/laptop/reviews/best/by-usage/programming)\n\nThese laptops were chosen based on their performance, usability for coding, build quality, and battery life, catering to different user needs and budgets. Each model offers unique benefits suitable for various programming requirements
    TEXT
    "Which laptop models offer the best performance and features for software development tasks?" => <<-TEXT.squish
        Based on the latest information from various sources, here are the top laptops recommended for software engineering students currently available in the market:\n\n1. **Lenovo ThinkPad X1 Carbon Gen 12**\n   - **Pros**: Ultralight and portable with excellent battery life (~14 hours), high-quality OLED display, and a comfortable keyboard.\n   - **Cons**: Expensive, limited ports.\n   - **Recommendation**: Ideal for professionals needing a lightweight, robust laptop for demanding tasks.\n   - **Source**: [TechRadar](https://www.techradar.com/news/the-best-laptops-for-engineering-students)\n\n2. **Dell XPS 15**\n   - **Pros**: High-performance Intel Core i7/i9 processors, impressive NVIDIA GPU options, excellent build quality, and optional 4K display.\n   - **Cons**: Expensive and lower battery life with the 4K display.\n   - **Recommendation**: Best for students who need reliable performance for intensive software applications.\n   - **Source**: [The Tech Edvocate](https://www.thetechedvocate.org/best-laptops-for-engineering-students/)\n\n3. **Apple MacBook Air (M3)**\n   - **Pros**: Lightweight, excellent performance, long battery life (~14 hours).\n   - **Cons**: Base model has limited RAM and storage.\n   - **Recommendation**: Best suited for those who prefer macOS and seek portability without compromising performance.\n   - **Source**: [TechRadar](https://www.techradar.com/news/the-best-laptops-for-engineering-students)\n\n4. **Asus ROG Zephyrus G14**\n   - **Pros**: Powerful AMD Ryzen processors, NVIDIA graphics, portable, and good battery life.\n   - **Cons**: Some models lack a webcam and can run hot under heavy loads.\n   - **Recommendation**: A blend of power and portability, particularly for CAD or 3D modeling.\n   - **Source**: [The Tech Edvocate](https://www.thetechedvocate.org/best-laptops-for-engineering-students/)\n\n5. **HP Victus 15**\n   - **Pros**: Great value, solid performance, ideal for work and play.\n   - **Cons**: Limited battery life (~4.5 hours).\n   - **Recommendation**: A strong choice for students looking for a cost-effective option without sacrificing essential features.\n   - **Source**: [TechRadar](https://www.techradar.com/news/the-best-laptops-for-engineering-students)\n\nThese laptops were chosen based on their performance, portability, and suitability for software engineering tasks. They cater to various needs, from high-performance computing to budget-friendly options, making them suitable for different student requirements. Each laptop is recommended based on its balance of features, price, and the specific needs of software engineering students.
    TEXT
    }

     VCR.use_cassette("analysis/entity_extractor/de") do
      report = Report.create!(query: "beste Autos für Frauen über 45 Jahren", brand_info: "Volkswagen Tiguan", owner: users(:jane))
      extraction = Analysis::EntityExtractor.new(answers: answers, language: "deu", report: report)
      assert extraction.valid?, extraction.errors.full_messages

      assert extraction.perform
      assert_equal({ "brands"=>[], "products"=>[ { "name"=>"Lenovo ThinkPad X1 Carbon Gen 12", "links"=>[ "https://www.techradar.com/news/the-best-laptops-for-engineering-students" ], "positions"=>[ 1 ] }, { "name"=>"Dell XPS 15", "links"=>[ "https://www.thetechedvocate.org/best-laptops-for-engineering-students/" ], "positions"=>[ 2 ] }, { "name"=>"Apple MacBook Air (M3)", "links"=>[ "https://www.techradar.com/news/the-best-laptops-for-engineering-students" ], "positions"=>[ 3 ] }, { "name"=>"Asus ROG Zephyrus G14", "links"=>[ "https://www.thetechedvocate.org/best-laptops-for-engineering-students/" ], "positions"=>[ 4 ] }, { "name"=>"HP Victus 15", "links"=>[ "https://www.techradar.com/news/the-best-laptops-for-engineering-students" ], "positions"=>[ 5 ] }, { "name"=>"Apple MacBook Pro 14-inch (2023)", "links"=>[ "https://www.techradar.com/news/best-laptop-for-programming" ], "positions"=>[ 1 ] }, { "name"=>"Dell XPS 15 (2023)", "links"=>[ "https://www.xda-developers.com/best-laptops-programming/" ], "positions"=>[ 2 ] }, { "name"=>"Lenovo ThinkPad X1 Carbon Gen 9", "links"=>[ "https://www.pcworld.com/article/705488/best-laptops-for-programming.html" ], "positions"=>[ 3 ] }, { "name"=>"Asus VivoBook Pro 16X OLED", "links"=>[ "https://www.pcworld.com/article/705488/best-laptops-for-programming.html" ], "positions"=>[ 4 ] }, { "name"=>"Apple MacBook Air M2", "links"=>[ "https://www.xda-developers.com/best-laptops-programming/" ], "positions"=>[ 5 ] }, { "name"=>"Lenovo ThinkPad P1 Gen 7 (2024)", "links"=>[ "https://www.rtings.com/laptop/reviews/best/by-usage/programming" ], "positions"=>[ 6 ] } ], "links"=>{ "https://www.techradar.com/news/the-best-laptops-for-engineering-students"=>{ "product_hits"=>3, "brand_hits"=>0, "orphan_hits"=>1, "brands"=>[], "products"=>[ "Lenovo ThinkPad X1 Carbon Gen 12", "Apple MacBook Air (M3)", "HP Victus 15" ] }, "https://www.thetechedvocate.org/best-laptops-for-engineering-students/"=>{ "product_hits"=>2, "brand_hits"=>0, "orphan_hits"=>1, "brands"=>[], "products"=>[ "Dell XPS 15", "Asus ROG Zephyrus G14" ] }, "https://www.techradar.com/news/best-laptop-for-programming"=>{ "product_hits"=>1, "brand_hits"=>0, "orphan_hits"=>0, "brands"=>[], "products"=>[ "Apple MacBook Pro 14-inch (2023)" ] }, "https://www.xda-developers.com/best-laptops-programming/"=>{ "product_hits"=>2, "brand_hits"=>0, "orphan_hits"=>0, "brands"=>[], "products"=>[ "Dell XPS 15 (2023)", "Apple MacBook Air M2" ] }, "https://www.pcworld.com/article/705488/best-laptops-for-programming.html"=>{ "product_hits"=>2, "brand_hits"=>0, "orphan_hits"=>0, "brands"=>[], "products"=>[ "Lenovo ThinkPad X1 Carbon Gen 9", "Asus VivoBook Pro 16X OLED" ] }, "https://www.rtings.com/laptop/reviews/best/by-usage/programming"=>{ "product_hits"=>1, "brand_hits"=>0, "orphan_hits"=>0, "brands"=>[], "products"=>[ "Lenovo ThinkPad P1 Gen 7 (2024)" ] } } },
        extraction.result
      )
     end
  end

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

    VCR.use_cassette("analysis/entity_extractor/deu") do
      report = Report.create!(query: "beste Autos für Frauen über 45 Jahren", brand_info: "Volkswagen Tiguan", owner: users(:jane))
      extraction = Analysis::EntityExtractor.new(answers: answers, language: "deu", report: report)
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
            "orphan_hits" => 1,
            "brands" => [ "Volkswagen" ],
            "products" => [ "Volkswagen VW ID.7" ]
          },
          "https://www.autoscout24.de/informieren/ratgeber/auto-sicherheit/ncap-sicherste-autos/" => {
            "product_hits" => 1,
            "brand_hits" => 1,
            "orphan_hits" => 1,
            "brands" => [ "NIO" ],
            "products" => [ "NIO ET5" ]
          },
          "https://www.finn.com/de-DE/auto/bestenliste/sicherstes-auto" => {
            "product_hits" => 1,
            "brand_hits" => 1,
            "orphan_hits" => 1,
            "brands" => [ "Smart" ],
            "products" => [ "Smart #3" ]
          },
          "https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos" => {
            "product_hits" => 2,
            "brand_hits" => 1,
            "orphan_hits" => 1,
            "brands" => [ "Tesla" ],
            "products" => [ "Tesla Model 3", "Tesla Model Y" ]
          },
          "https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap-2022/" => {
            "product_hits" => 2,
            "brand_hits" => 1,
            "orphan_hits" => 1,
            "brands" => [ "Volvo" ],
            "products" => [ "Volvo XC60", "Volvo XC90" ]
          }
        }
      },
      extraction.result)
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

    aggregated = Analysis::EntityExtractor.aggregate(entities)

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
