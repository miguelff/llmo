require "test_helper"

class ResultTest
    class BrandHealthTest < ActiveSupport::TestCase
        test "perform smoke test" do
            VCR.use_cassette("result/brand_health/perform_smoke_test") do
                report = Report.create!(query: "What is the best laptop in the market?", cohort: "Software Engineering students", brand_info: "Dell XPS", owner: users(:jane))

                allow(report).to receive(:analyses).withand_return([
                    "type": "Analysis::EntityExtractor",
                    "result": {
                        "brands": [],
                        "products": [
                            { "name": "Apple MacBook Air", "score": 100.0, "rank": 1 },
                            { "name": "Dell XPS 13", "score": 75.0, "rank": 2 },
                            { "name": "HP Spectre x360", "score": 66.67, "rank": 3 },
                            { "name": "Lenovo ThinkPad X1 Carbon", "score": 62.5, "rank": 4 },
                            { "name": "Asus ZenBook 14", "score": 55.0, "rank": 5 }
                        ],
                        "you": {
                            "product_rank": 2,
                            "other_product_rank": 1,
                            "brand_rank": 2,
                            "reason": "The Dell XPS 13 is ranked 2nd among laptops, indicating its strong performance and popularity. Dell as a brand is also highly regarded, holding the 2nd rank overall, which reflects its reputation for quality and innovation in the laptop market."
                        }
                    }
                ])

                brand_health = Result::BrandHealth.new(report: report)
            end
        end
    end
end


=begin
[
  [
    "Analysis::LanguageDetector",
    "eng"
  ],
  [
    "Analysis::QuestionSynthesis",
    [
      "What are the top laptops recommended for software engineering students currently available in the market?",
      "Which laptop models offer the best performance and features for software development tasks?"
    ]
  ],
  [
    "Analysis::QuestionAnswering",
    [
      {
        "question": "What are the top laptops recommended for software engineering students currently available in the market?",
        "answer": "Based on the analysis from various sources, here are some of the best laptop models for software development tasks in 2023, along with explanations for their selection:\n\n1. **Apple MacBook Pro 14-inch (2023)**:\n   - **Why**: Known for its M2 Pro/Max chips, this laptop offers top-tier performance, excellent battery life (nearly 20 hours), and a great display. It's ideal for complex workloads and can run both macOS and Windows.\n   - **Source**: [TechRadar](https://www.techradar.com/news/best-laptop-for-programming)\n\n2. **Dell XPS 15 (2023)**:\n   - **Why**: Offers powerful 13th Gen Intel CPUs, a stunning 3.5K OLED display, and upgradeable RAM and storage, making it versatile for different development environments including Linux.\n   - **Source**: [XDA Developers](https://www.xda-developers.com/best-laptops-programming/)\n\n3. **Lenovo ThinkPad X1 Carbon Gen 9**:\n   - **Why**: Known for its comfortable keyboard and durability, it features a Core i7 processor and 16GB of RAM, making it a great choice for business professionals who code.\n   - **Source**: [PCWorld](https://www.pcworld.com/article/705488/best-laptops-for-programming.html)\n\n4. **Asus VivoBook Pro 16X OLED**:\n   - **Why**: Features a powerful Ryzen 9 5900HX processor and a stunning 4K OLED display, ideal for intensive programming tasks.\n   - **Source**: [PCWorld](https://www.pcworld.com/article/705488/best-laptops-for-programming.html)\n\n5. **Apple MacBook Air M2**:\n   - **Why**: Lightweight with excellent battery life and a high-resolution display, it's a great value option for those needing portability and solid performance.\n   - **Source**: [XDA Developers](https://www.xda-developers.com/best-laptops-programming/)\n\n6. **Lenovo ThinkPad P1 Gen 7 (2024)**:\n   - **Why**: Offers powerful Intel CPUs and an excellent user experience, suitable for multi-monitor setups and demanding tasks.\n   - **Source**: [RTINGS](https://www.rtings.com/laptop/reviews/best/by-usage/programming)\n\nThese laptops were chosen based on their performance, usability for coding, build quality, and battery life, catering to different user needs and budgets. Each model offers unique benefits suitable for various programming requirements."
      },
      {
        "question": "Which laptop models offer the best performance and features for software development tasks?",
        "answer": "Based on the latest information from various sources, here are the top laptops recommended for software engineering students currently available in the market:\n\n1. **Lenovo ThinkPad X1 Carbon Gen 12**\n   - **Pros**: Ultralight and portable with excellent battery life (~14 hours), high-quality OLED display, and a comfortable keyboard.\n   - **Cons**: Expensive, limited ports.\n   - **Recommendation**: Ideal for professionals needing a lightweight, robust laptop for demanding tasks.\n   - **Source**: [TechRadar](https://www.techradar.com/news/the-best-laptops-for-engineering-students)\n\n2. **Dell XPS 15**\n   - **Pros**: High-performance Intel Core i7/i9 processors, impressive NVIDIA GPU options, excellent build quality, and optional 4K display.\n   - **Cons**: Expensive and lower battery life with the 4K display.\n   - **Recommendation**: Best for students who need reliable performance for intensive software applications.\n   - **Source**: [The Tech Edvocate](https://www.thetechedvocate.org/best-laptops-for-engineering-students/)\n\n3. **Apple MacBook Air (M3)**\n   - **Pros**: Lightweight, excellent performance, long battery life (~14 hours).\n   - **Cons**: Base model has limited RAM and storage.\n   - **Recommendation**: Best suited for those who prefer macOS and seek portability without compromising performance.\n   - **Source**: [TechRadar](https://www.techradar.com/news/the-best-laptops-for-engineering-students)\n\n4. **Asus ROG Zephyrus G14**\n   - **Pros**: Powerful AMD Ryzen processors, NVIDIA graphics, portable, and good battery life.\n   - **Cons**: Some models lack a webcam and can run hot under heavy loads.\n   - **Recommendation**: A blend of power and portability, particularly for CAD or 3D modeling.\n   - **Source**: [The Tech Edvocate](https://www.thetechedvocate.org/best-laptops-for-engineering-students/)\n\n5. **HP Victus 15**\n   - **Pros**: Great value, solid performance, ideal for work and play.\n   - **Cons**: Limited battery life (~4.5 hours).\n   - **Recommendation**: A strong choice for students looking for a cost-effective option without sacrificing essential features.\n   - **Source**: [TechRadar](https://www.techradar.com/news/the-best-laptops-for-engineering-students)\n\nThese laptops were chosen based on their performance, portability, and suitability for software engineering tasks. They cater to various needs, from high-performance computing to budget-friendly options, making them suitable for different student requirements. Each laptop is recommended based on its balance of features, price, and the specific needs of software engineering students."
      }
    ]
  ],
  [
    "Analysis::InputClassifier",
    {
      "brand": "Dell",
      "product": "XPS",
      "type": "product"
    }
  ],
  [
    "Analysis::EntityExtractor",
    {
      "brands": [],
      "products": [
        {
          "name": "Apple MacBook Air",
          "links": [
            "https://www.apple.com/macbook-air/",
            "https://www.apple.com/macbook-air/"
          ],
          "positions": [
            1,
            1
          ]
        },
        {
          "name": "Dell XPS 13",
          "links": [
            "https://www.dell.com/en-us/shop/dell-laptops/xps-13-laptop/spd/xps-13-9310-laptop",
            "https://www.dell.com/en-us/shop/dell-laptops/xps-13-laptop/spd/xps-13-9310-laptop"
          ],
          "positions": [
            2,
            2
          ]
        },
        {
          "name": "HP Spectre x360",
          "links": [
            "https://www.hp.com/us-en/shop/hp-spectre-x360-laptop",
            "https://www.hp.com/us-en/shop/hp-spectre-x360-laptop"
          ],
          "positions": [
            3,
            3
          ]
        },
        {
          "name": "Lenovo ThinkPad X1 Carbon",
          "links": [
            "https://www.lenovo.com/us/en/laptops/thinkpad/thinkpad-x/ThinkPad-X1-Carbon-Gen-9/p/20XW0003US",
            "https://www.lenovo.com/us/en/laptops/thinkpad/thinkpad-x/ThinkPad-X1-Carbon-Gen-9/p/20XW0003US"
          ],
          "positions": [
            4,
            4
          ]
        }
      ],
      "links": {
        "https://www.apple.com/macbook-air/": {
          "product_hits": 2,
          "brand_hits": 0,
          "orphan_hits": 0,
          "brands": [],
          "products": [
            "Apple MacBook Air"
          ]
        },
        "https://www.dell.com/en-us/shop/dell-laptops/xps-13-laptop/spd/xps-13-9310-laptop": {
          "product_hits": 2,
          "brand_hits": 0,
          "orphan_hits": 0,
          "brands": [],
          "products": [
            "Dell XPS 13"
          ]
        },
        "https://www.hp.com/us-en/shop/hp-spectre-x360-laptop": {
          "product_hits": 2,
          "brand_hits": 0,
          "orphan_hits": 0,
          "brands": [],
          "products": [
            "HP Spectre x360"
          ]
        },
        "https://www.lenovo.com/us/en/laptops/thinkpad/thinkpad-x/ThinkPad-X1-Carbon-Gen-9/p/20XW0003US": {
          "product_hits": 2,
          "brand_hits": 0,
          "orphan_hits": 0,
          "brands": [],
          "products": [
            "Lenovo ThinkPad X1 Carbon"
          ]
        }
      }
    }
  ],
  [
    "Analysis::Competitors",
    {
      "overarching_term": "laptops",
      "term_attributes": [
        {
          "name": "Performance",
          "definition": "The overall speed and efficiency of the laptop, often measured by the processor type, RAM, and storage type.",
          "why": "Performance is crucial as it determines how well the laptop can handle tasks, applications, and multitasking, which directly affects user satisfaction."
        },
        {
          "name": "Battery Life",
          "definition": "The duration the laptop can operate on a single charge under typical usage conditions.",
          "why": "Battery life is essential for portability and convenience, especially for users who need to work on the go without frequent charging."
        },
        {
          "name": "Build Quality",
          "definition": "The durability and materials used in the construction of the laptop, including the keyboard, screen, and chassis.",
          "why": "Build quality impacts the longevity and reliability of the laptop, influencing customer perceptions of value and brand reputation."
        },
        {
          "name": "Display Quality",
          "definition": "The resolution, color accuracy, brightness, and overall visual experience provided by the laptop's screen.",
          "why": "Display quality is important for user experience, especially for tasks like graphic design, gaming, and media consumption."
        },
        {
          "name": "Price",
          "definition": "The cost of the laptop, which can vary widely based on specifications, brand, and features.",
          "why": "Price is a key factor for consumers when making purchasing decisions, and it helps to position the product within the competitive landscape."
        }
      ],
      "competition_scores": [
        {
          "name": "Apple MacBook Air",
          "scores": [
            {
              "attribute": "Performance",
              "score": "8/10",
              "reason": "The MacBook Air features Apple's M1/M2 chip, providing excellent performance for everyday tasks and software development."
            },
            {
              "attribute": "Battery Life",
              "score": "9/10",
              "reason": "With up to 14 hours of battery life, it is highly suitable for users on the go."
            },
            {
              "attribute": "Build Quality",
              "score": "8/10",
              "reason": "The aluminum chassis is durable and lightweight, contributing to its premium feel."
            },
            {
              "attribute": "Display Quality",
              "score": "8/10",
              "reason": "The Retina display offers high resolution and good color accuracy, making it suitable for design work."
            },
            {
              "attribute": "Price",
              "score": "7/10",
              "reason": "While it is on the higher end for ultrabooks, it offers good value for the performance and features."
            }
          ]
        },
        {
          "name": "Dell XPS 13",
          "scores": [
            {
              "attribute": "Performance",
              "score": "8/10",
              "reason": "Equipped with Intel's latest processors, it handles multitasking and demanding applications well."
            },
            {
              "attribute": "Battery Life",
              "score": "8/10",
              "reason": "Offers decent battery life, around 12 hours, which is good for a compact laptop."
            },
            {
              "attribute": "Build Quality",
              "score": "9/10",
              "reason": "The XPS series is known for its premium materials and sturdy construction."
            },
            {
              "attribute": "Display Quality",
              "score": "9/10",
              "reason": "The InfinityEdge display provides excellent color accuracy and brightness."
            },
            {
              "attribute": "Price",
              "score": "6/10",
              "reason": "It is relatively expensive compared to other ultrabooks with similar specs."
            }
          ]
        },
        {
          "name": "HP Spectre x360",
          "scores": [
            {
              "attribute": "Performance",
              "score": "8/10",
              "reason": "Features powerful Intel processors, making it suitable for both productivity and creative tasks."
            },
            {
              "attribute": "Battery Life",
              "score": "8/10",
              "reason": "Offers around 12-13 hours of battery life, which is competitive for a convertible laptop."
            },
            {
              "attribute": "Build Quality",
              "score": "9/10",
              "reason": "The premium metal design and hinge mechanism enhance durability and aesthetics."
            },
            {
              "attribute": "Display Quality",
              "score": "9/10",
              "reason": "The OLED display option provides stunning visuals and color accuracy."
            },
            {
              "attribute": "Price",
              "score": "7/10",
              "reason": "While it offers premium features, the price is on the higher side."
            }
          ]
        },
        {
          "name": "Lenovo ThinkPad X1 Carbon",
          "scores": [
            {
              "attribute": "Performance",
              "score": "9/10",
              "reason": "Known for its powerful performance, especially with the latest Intel processors."
            },
            {
              "attribute": "Battery Life",
              "score": "9/10",
              "reason": "Exceptional battery life, often exceeding 14 hours, ideal for professionals."
            },
            {
              "attribute": "Build Quality",
              "score": "10/10",
              "reason": "Renowned for its robust build quality and military-grade durability."
            },
            {
              "attribute": "Display Quality",
              "score": "8/10",
              "reason": "Good display options, though not as vibrant as OLED alternatives."
            },
            {
              "attribute": "Price",
              "score": "6/10",
              "reason": "Higher price point, but justified by performance and build quality."
            }
          ]
        },
        {
          "name": "Dell XPS 15",
          "scores": [
            {
              "attribute": "Performance",
              "score": "9/10",
              "reason": "High-performance options with powerful CPUs and GPUs, suitable for demanding tasks."
            },
            {
              "attribute": "Battery Life",
              "score": "7/10",
              "reason": "Battery life can be lower with 4K displays, averaging around 8-10 hours."
            },
            {
              "attribute": "Build Quality",
              "score": "9/10",
              "reason": "Excellent build quality with premium materials and design."
            },
            {
              "attribute": "Display Quality",
              "score": "10/10",
              "reason": "The 4K OLED display offers stunning visuals and color accuracy."
            },
            {
              "attribute": "Price",
              "score": "5/10",
              "reason": "Very expensive, especially with higher-end configurations."
            }
          ]
        }
      ]
    }
  ]
]
=end
