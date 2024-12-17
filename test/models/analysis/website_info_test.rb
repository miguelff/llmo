require "test_helper"

class WebsiteInfoTest < ActiveSupport::TestCase
  test "constructor is private" do
    assert_raises(NoMethodError) { Analysis::WebsiteInfo.new }
  end

  test "validating the input when protocol is missing" do
    info = Analysis::WebsiteInfo.for(url: "mararodriguez.es/")
    assert info.valid?
    assert_equal "http://mararodriguez.es/", info.input["url"]
  end

  test "retrying with www" do
    VCR.use_cassette("analysis/website_info/www.mararodriguez.es") do
      info = Analysis::WebsiteInfo.for(url: "https://www.mararodriguez.es/")
      assert info.valid?
      assert info.perform_and_save
    end
  end

  test "validating the input" do
    info = Analysis::WebsiteInfo.for(url: "http:www.mararodriguez.es/")
    assert_not info.valid?
    assert_equal [ "Input Url doesn't have a valid format" ], info.errors.full_messages
  end

  test "finding information about a website" do
    VCR.use_cassette("analysis/website_info/mararodriguez.es") do
      info = Analysis::WebsiteInfo.for(url: "https://mararodriguez.es/")
      assert info.valid?
      assert info.perform_and_save

      result = info.presenter
      assert_equal "https://mararodriguez.es/", result.url
      assert_equal "Mara Rodriguez Design - Branding, Packaging y Diseño Gráfico Asturias", result.title
      assert_equal [], result.keywords
      assert_equal <<-TOC.squish, result.toc.squish
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

      assert_equal({
        "viewport"=>"width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover",
        "robots"=>"index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1",
        "description"=>"Mara Rodriguez es un estudio de Diseño gráfico en Asturias especializado en Packaging y Branding. Estamos en Gijón y trabajamos con clientes nacionales e internacionales.",
        "og:locale"=>"es_ES",
        "og:locale:alternate"=>"en_GB",
        "og:type"=>"website",
        "og:title"=>"Mara Rodriguez Design - Branding, Packaging y Diseño Gráfico Asturias",
        "og:description"=>"Mara Rodriguez es un estudio de Diseño gráfico en Asturias especializado en Packaging y Branding. Estamos en Gijón y trabajamos con clientes nacionales e internacionales.",
        "og:url"=>"https://mararodriguez.es/",
        "og:site_name"=>"Mara Rodriguez - Design",
        "article:publisher"=>"https://www.facebook.com/Oloramara.Design",
        "article:modified_time"=>"2022-03-24T16:38:56+00:00",
        "twitter:card"=>"summary_large_image",
        "twitter:label1"=>"Tiempo de lectura",
        "twitter:data1"=>"2 minutos",
        "generator"=>"Powered by WPBakery Page Builder - drag and drop page builder for WordPress.",
        "msapplication-TileImage"=>"https://mararodriguez.es/wp-content/uploads/2019/05/cropped-mR_600x600-1-270x270.jpg"
      }, result.meta_tags.to_h)
    end
  end

  test "a website does not exist" do
    VCR.use_cassette("analysis/website_info/does_not_exist") do
      info = Analysis::WebsiteInfo.for(url: "https://not_existing_website_12345.gg/")
      assert info.perform_and_save

      assert_equal "Failed to fetch the page https://not_existing_website_12345.gg/ after 3 attempts", info.error
    end
  end
end
