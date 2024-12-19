require "test_helper"

class Analysis::YourWebsiteTest < ActiveSupport::TestCase
  test "constructor is private" do
    assert_raises(NoMethodError) { Analysis::YourWebsite.new }
  end

  test "validating the input when protocol is missing" do
    info = Analysis::YourWebsite.for_new_analysis(url: "mararodriguez.es/")
    assert info.valid?
    assert_equal "http://mararodriguez.es/", info.input["url"]
  end

  test "retrying with www" do
    VCR.use_cassette("analysis/your_website/www.mararodriguez.es") do
      info = Analysis::YourWebsite.for_new_analysis(url: "https://www.mararodriguez.es/")
      assert info.valid?
      assert info.perform_if_valid
    end
  end

  test "validating the input" do
    info = Analysis::YourWebsite.for_new_analysis(url: "http:www.mararodriguez.es/")
    assert_not info.valid?
    assert_equal [ "Url doesn't have a valid format" ], info.errors.full_messages
  end

  test "finding information about a website" do
    VCR.use_cassette("analysis/your_website/mararodriguez.es") do
      info = Analysis::YourWebsite.for_new_analysis(url: "https://mararodriguez.es/")
      assert info.valid?
      assert info.perform_if_valid

      result = info.presenter
      assert_equal "https://mararodriguez.es/", result.url
      assert_equal "Mara Rodriguez Design - Branding, Packaging y Diseño Gráfico Asturias", result.title
      assert_equal(
        [
          { "level" => 1, "text" => " ¡Hola! Somos un estudio de diseño creativo en Asturias, locas por\n" },
          { "level" => 2, "text" => "Cocada Snacks" },
          { "level" => 2, "text" => "Mix&Twist Zumos" },
          { "level" => 2, "text" => "Alskin Cosmetics" },
          { "level" => 2, "text" => "Oquendo – Grandes Orígenes" },
          { "level" => 2, "text" => "TOA Hemp" },
          { "level" => 2, "text" => "SillyBilly Tortitas" },
          { "level" => 2, "text" => "Popitas" },
          { "level" => 2, "text" => "SillyBilly Snacks" },
          { "level" => 2, "text" => "SuperSaludables" },
          { "level" => 2, "text" => "TOA" },
          { "level" => 1, "text" => "El Diseño Gráfico, nuestra pasión" },
          { "level" => 3, "text" => "Llevamos desde 2013 trabajando con clientes nacionales e internacionales. Buscamos la mejor solución para las empresas, desde una perspectiva creativa y divertida. El Packaging, el Branding, el Diseño y Asturias son nuestras mayores pasiones" },
          { "level" => 2, "text" => "Cervezas FEM" },
          { "level" => 2, "text" => "Pantry Ice Cream" },
          { "level" => 2, "text" => "Teangle" },
          { "level" => 2, "text" => "DOG" },
          { "level" => 2, "text" => "Smart Snacks" },
          { "level" => 2, "text" => "Miel Picu Moros" },
          { "level" => 2, "text" => "I´M A NUT" },
          { "level" => 2, "text" => "Dersia Cosmetics" },
          { "level" => 2, "text" => "Akaw – Helado Artesanal" },
          { "level" => 2, "text" => "DipMates" }
        ], result.toc)

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
    VCR.use_cassette("analysis/your_website/does_not_exist") do
      info = Analysis::YourWebsite.for_new_analysis(url: "https://not_existing_website_12345.gg/")
      assert info.perform_if_valid

      assert_equal "Failed to fetch the page https://not_existing_website_12345.gg/ after 3 attempts", info.error
    end
  end
end
