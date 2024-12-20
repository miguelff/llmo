require "test_helper"

class Analysis::YourBrandTest < ActiveSupport::TestCase
    def your_website(url:)
        Analysis::YourWebsite::Form.new(url: url, analysis: Analysis::Record.create!)
    end

    def your_brand(website_info)
        Analysis::YourBrand.new(input: website_info, analysis: Analysis::Record.create!)
    end

    test "canary" do
      VCR.use_cassette("analysis/brand/mararodriguez.es") do
        website_info = {
          url: "https://mararodriguez.es/",
          title: "Mara Rodriguez Design - Branding, Packaging y Diseño Gráfico Asturias",
          toc: [
            { level: 1, text: "¡Hola! Somos un estudio de diseño creativo en Asturias, locas por" },
            { level: 2, text: "Cocada Snacks" },
            { level: 2, text: "Mix&Twist Zumos" },
            { level: 2, text: "Alskin Cosmetics" },
            { level: 2, text: "Oquendo – Grandes Orígenes" },
            { level: 2, text: "TOA Hemp" },
            { level: 2, text: "SillyBilly Tortitas" },
            { level: 2, text: "Popitas" },
            { level: 2, text: "SillyBilly Snacks" },
            { level: 2, text: "SuperSaludables" },
            { level: 2, text: "TOA" },
            { level: 1, text: "El Diseño Gráfico, nuestra pasión" },
            { level: 2, text: "Llevamos desde 2013 trabajando con clientes nacionales e internacionales. Buscamos la mejor solución para las empresas, desde una perspectiva creativa y divertida. El Packaging, el Branding, el Diseño y Asturias son nuestras mayores pasiones" },
            { level: 2, text: "Cervezas FEM" },
            { level: 2, text: "Pantry Ice Cream" },
            { level: 2, text: "Teangle" },
            { level: 2, text: "DOG" },
            { level: 2, text: "Smart Snacks" },
            { level: 2, text: "Miel Picu Moros" },
            { level: 2, text: "I´M A NUT" },
            { level: 2, text: "Dersia Cosmetics" },
            { level: 2, text: "Akaw – Helado Artesanal" },
            { level: 2, text: "DipMates" }
          ],
          meta_tags: {
            "viewport" => "width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover",
            "robots" => "index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1",
            "description" => "Mara Rodriguez es un estudio de Diseño gráfico en Asturias especializado en Packaging y Branding. Estamos en Gijón y trabajamos con clientes nacionales e internacionales.",
            "og:locale" => "es_ES",
            "og:locale:alternate" => "en_GB",
            "og:type" => "website",
            "og:title" => "Mara Rodriguez Design - Branding, Packaging y Diseño Gráfico Asturias",
            "og:description" => "Mara Rodriguez es un estudio de Diseño gráfico en Asturias especializado en Packaging y Branding. Estamos en Gijón y trabajamos con clientes nacionales e internacionales.",
            "og:url" => "https://mararodriguez.es/",
            "og:site_name" => "Mara Rodriguez - Design",
            "article:publisher" => "https://www.facebook.com/Oloramara.Design",
            "article:modified_time" => "2022-03-24T16:38:56+00:00",
            "twitter:card" => "summary_large_image",
            "twitter:label1" => "Tiempo de lectura",
            "twitter:data1" => "2 minutos",
            "generator" => "Powered by WPBakery Page Builder - drag and drop page builder for WordPress.",
            "msapplication-TileImage" => "https://mararodriguez.es/wp-content/uploads/2019/05/cropped-mR_600x600-1-270x270.jpg"
          }
        }

        brand_info = Analysis::YourBrand.for_new_analysis(website_info: Analysis::Presenters::Website.from_json(website_info))
        assert brand_info.valid?
        assert brand_info.perform
        assert_matches_snapshot brand_info.result
      end
   end

    test "Use case 1: deurbe" do
      VCR.use_cassette("analysis/brand/deurbe.com") do
        website_info = your_website(url: "https://deurbe.com/")
        assert website_info.valid?
        assert website_info.perform

        brand_info = your_brand(website_info)
        assert brand_info.valid?
        assert brand_info.perform
        assert_matches_snapshot brand_info.result
      end
    end

    test "Use case 2: tablas surf" do
      VCR.use_cassette("analysis/brand/tablassurfshop.com") do
        website_info = your_website(url: "https://www.tablassurfshop.com")
        assert website_info.valid?
        assert website_info.perform

        brand_info = your_brand(website_info)
        assert brand_info.valid?
        assert brand_info.perform
        assert_matches_snapshot brand_info.result
      end
    end

    test "Use case 3: capchase" do
      VCR.use_cassette("analysis/brand/capchase.com") do
        website_info = your_website(url: "https://www.capchase.com/")
        assert website_info.valid?
        assert website_info.perform

        brand_info = your_brand(website_info)
        assert brand_info.valid?
        assert brand_info.perform
        assert_matches_snapshot brand_info.result
      end
    end

    test "Use case 4: Reveni" do
      VCR.use_cassette("analysis/brand/reveni.com") do
        website_info = your_website(url: "https://www.reveni.com/")
        assert website_info.valid?
        assert website_info.perform

        brand_info = your_brand(website_info)
        assert brand_info.valid?
        assert brand_info.perform

        assert_matches_snapshot brand_info.result
      end
    end

    test "Use case 5: BMW 3 Series (landing page, not website)" do
      VCR.use_cassette("analysis/brand/bmw_3_series") do
        website_info = your_website(url: "https://www.bmw.es/es/coches-bmw/serie-3/bmw-serie-3-berlina/caracteristicas.html")
        assert website_info.valid?
        assert website_info.perform

        brand_info = your_brand(website_info)
        assert brand_info.valid?
        assert brand_info.perform

        assert_matches_snapshot brand_info.result
      end
    end
end
