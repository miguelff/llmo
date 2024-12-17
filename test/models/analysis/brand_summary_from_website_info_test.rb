require "test_helper"

class Analysis::BrandSummaryFromWebsiteInfoTest < ActiveSupport::TestCase
    test "canary" do
      VCR.use_cassette("analysis/brand_summary_from_website_info/mararodriguez.es") do
        website_info = {
          url: "https://mararodriguez.es/",
          title: "Mara Rodriguez Design - Branding, Packaging y Diseño Gráfico Asturias",
          toc: <<-TOC.squish,
            - ¡Hola! Somos un estudio de diseño creativo en Asturias, locas por
              - Cocada Snacks
              - Mix&Twist Zumos
              - Alskin Cosmetics
              - Oquendo – Grandes Orígenes
              - TOA Hemp
              - SillyBilly Tortitas
              - Popitas
              - SillyBilly Snacks
              - SuperSaludables
              - TOA
            - El Diseño Gráfico, nuestra pasión
              - Llevamos desde 2013 trabajando con clientes nacionales e internacionales. Buscamos la mejor solución para las empresas, desde una perspectiva creativa y divertida. El Packaging, el Branding, el Diseño y Asturias son nuestras mayores pasiones
              - Cervezas FEM
              - Pantry Ice Cream
              - Teangle
              - DOG
              - Smart Snacks
              - Miel Picu Moros
              - I´M A NUT
              - Dersia Cosmetics
              - Akaw – Helado Artesanal
              - DipMates
          TOC
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

        brand_info = Analysis::BrandSummaryFromWebsiteInfo.for(website_info: Analysis::Presenters::WebsiteInfo.from_json(website_info))
        assert brand_info.valid?
        assert brand_info.perform_and_save

        assert brand_info.presenter.complete?
        assert_matches_snapshot brand_info.presenter.to_h
      end
   end

    test "integrated with website info step" do
      VCR.use_cassette("analysis/brand_summary_from_website_info/deurbe.com") do
        website_info = Analysis::WebsiteInfo.for(url: "https://deurbe.com/")
        assert website_info.valid?
        assert website_info.perform_and_save

        brand_info = Analysis::BrandSummaryFromWebsiteInfo.for(website_info: website_info.presenter)
        assert brand_info.valid?
        assert brand_info.perform_and_save

        assert brand_info.presenter.complete?
        assert_matches_snapshot brand_info.presenter.to_h
      end
    end

    test "Use case 1: tablas surf" do
      VCR.use_cassette("analysis/brand_summary_from_website_info/tablassurfshop.com") do
        website_info = Analysis::WebsiteInfo.for(url: "https://www.tablassurfshop.com")
        assert website_info.valid?
        assert website_info.perform_and_save

        brand_info = Analysis::BrandSummaryFromWebsiteInfo.for(website_info: website_info.presenter)
        assert brand_info.valid?
        assert brand_info.perform_and_save

        assert brand_info.presenter.complete?
        assert_matches_snapshot brand_info.presenter.to_h
      end
    end

    test "Use case 2: capchase" do
      VCR.use_cassette("analysis/brand_summary_from_website_info/capchase.com") do
        website_info = Analysis::WebsiteInfo.for(url: "https://www.capchase.com/")
        assert website_info.valid?
        assert website_info.perform_and_save

        brand_info = Analysis::BrandSummaryFromWebsiteInfo.for(website_info: website_info.presenter)
        assert brand_info.valid?
        assert brand_info.perform_and_save

        assert_equal brand_info.presenter.complete?, true
        assert_matches_snapshot brand_info.presenter.to_h
      end
    end

    test "Use case 3: Reveni" do
      VCR.use_cassette("analysis/brand_summary_from_website_info/reveni.com") do
        website_info = Analysis::WebsiteInfo.for(url: "https://www.reveni.com/")
        assert website_info.valid?
        assert website_info.perform_and_save

        brand_info = Analysis::BrandSummaryFromWebsiteInfo.for(website_info: website_info.presenter)
        assert brand_info.valid?
        assert brand_info.perform_and_save

        assert_equal brand_info.presenter.complete?, true
        assert_matches_snapshot brand_info.presenter.to_h
      end
    end

    test "Use case 3: BMW 3 Series (landing page, not website)" do
      VCR.use_cassette("analysis/brand_summary_from_website_info/bmw_3_series") do
        website_info = Analysis::WebsiteInfo.for(url: "https://www.bmw.es/es/coches-bmw/serie-3/bmw-serie-3-berlina/caracteristicas.html")
        assert website_info.valid?
        assert website_info.perform_and_save

        brand_info = Analysis::BrandSummaryFromWebsiteInfo.for(website_info: website_info.presenter)
        assert brand_info.valid?
        assert brand_info.perform_and_save

        assert_equal brand_info.presenter.complete?, true
        assert_matches_snapshot brand_info.presenter.to_h
      end
    end
end
