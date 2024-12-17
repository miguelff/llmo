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

        assert_equal brand_info.presenter.complete?, true
        expected_brand_info = {
          name: "Mara Rodriguez",
          category: "Design",
          description: "Mara Rodriguez es un estudio de Diseño gráfico en Asturias especializado en Packaging y Branding. Trabajamos con clientes nacionales e internacionales.",
          region: "Asturias",
          keywords: [
            { "value" => "diseño gráfico Asturias" },
            { "value" => "branding Asturias" },
            { "value" => "packaging Asturias" },
            { "value" => "estudio de diseño Asturias" },
            { "value" => "diseño creativo Asturias" }
          ],
          competitors: [
            { "name" => "Pixelbox", "url" => "https://www.pixelbox.es/" },
            { "name" => "Kore Branding", "url" => "https://www.korebranding.es/" },
            { "name" => "Veintidos", "url" => "https://www.veintidos.es/" },
            { "name" => "Packastur", "url" => "https://packastur.com/" },
            { "name" => "DIL SE Estudio Creativo", "url" => "https://dilsecreativo.com/" },
            { "name" => "Matteria Creativa", "url" => "https://www.matteriacreativa.com/" }
          ]
        }
        assert_equal(expected_brand_info, brand_info.presenter.to_h)
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

        assert_equal brand_info.presenter.complete?, true
        assert_equal(
          {
            name: "deurbe arquitectura",
            category: "Architecture and Urbanism",
            description: "DEURBE ARQUITECTURA is a company founded in 1990 that integrates various disciplines related to architecture, urbanism, and land management, providing personalized advice and legal representation for administrative processes.",
            region: "Bizkaia, Spain",
            keywords: [
              { "value" => "arquitectura Bizkaia" },
              { "value" => "urbanismo Santurti" },
              { "value" => "interiorismo Bilbao" },
              { "value" => "gestión del suelo Bizkaia" },
              { "value" => "licencias arquitectónicas Santurti" }
            ],
            competitors: [
              { "name" => "Orbis Arquitectura", "url" => "https://orbisarquitectura.com/" },
              { "name" => "Aiertar Arquitectura", "url" => "https://aiertarkitektura.eus/estudio-arquitectura-bizkaia/" },
              { "name" => "Tandem Arquitectura", "url" => "https://tandemarquitectura.com/" },
              { "name" => "Arquiplan", "url" => "https://arquiplan.com/" },
              { "name" => "Hinojal Arquitectos", "url" => "https://hinojalarquitectos.com/" },
              { "name" => "Bilbao Interiorismo", "url" => "https://bilbaointeriorismo.com/" },
              { "name" => "SUBE Susaeta Interiorismo", "url" => "https://subeinteriorismo.com/" },
              { "name" => "Natalia Zubizarreta", "url" => "https://www.nataliazubizarreta.com/" },
              { "name" => "Urbana Interiorismo", "url" => "https://urbanainteriorismo.com/" }
            ]
          },
          brand_info.presenter.to_h
        )
      end
    end

    test "Use case 1: tablas surf" do
      VCR.use_cassette("analysis/brand_summary_from_website_info/tablasurf.com") do
        website_info = Analysis::WebsiteInfo.for(url: "https://www.tablassurfshop.com")
        assert website_info.valid?
        assert website_info.perform_and_save

        brand_info = Analysis::BrandSummaryFromWebsiteInfo.for(website_info: website_info.presenter)
        assert brand_info.valid?
        assert brand_info.perform_and_save

        assert_equal brand_info.presenter.complete?, true
        assert_equal(
          {
            name: "Tablas Surf Shop",
            category: "Sporting Goods",
            description: "En nuestra tienda online encontrarás todo el material necesario para practicar el Surf, el SUP o el Skate. Especialistas en Surf desde 1979.",
            region: "Spain",
            keywords: [
              { "value" => "tienda surf" },
              { "value" => "tienda surf online" },
              { "value" => "tienda skate online" },
              { "value" => "material surf España" },
              { "value" => "comprar surf online" }
            ],
            competitors: [
              { "name" => "Mundo Surf", "url" => "https://www.mundo-surf.com/" },
              { "name" => "Teiron Surf", "url" => "https://www.teironsurf.com/tienda/" },
              { "name" => "Surf Market", "url" => "https://www.surfmarket.org/es/" },
              { "name" => "Styling Surf", "url" => "https://stylingsurf.com/" },
              { "name" => "Surf Shop Online", "url" => "https://surfshoponline.com/" },
              { "name" => "Almarima", "url" => "https://almarima.com/es/" },
              { "name" => "Nomadas Surf", "url" => "https://www.nomadassurf.com/" },
              { "name" => "Skate Spain", "url" => "https://skatespain.com/" },
              { "name" => "Titus Shop", "url" => "https://www.titus-shop.com/es/" },
              { "name" => "Skatedeluxe", "url" => "https://www.skatedeluxe.com/es" }
            ]
          },
          brand_info.presenter.to_h
        )
      end
    end
end
