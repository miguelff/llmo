require "test_helper"

class WebsiteInfoTest < ActiveSupport::TestCase
  test "finding information about a website" do
    VCR.use_cassette("analysis/website_info/mararodriguez.es") do
      info = Analysis::WebsiteInfo.new(url: "https://mararodriguez.es/")
      assert info.perform_and_save

      result = info.result_presenter
      assert_equal "https://mararodriguez.es/", result.url
      assert_equal "Mara Rodriguez Design - Branding, Packaging y Diseño Gráfico Asturias", result.title
      assert_equal "Mara Rodriguez es un estudio de Diseño gráfico en Asturias especializado en Packaging y Branding. Estamos en Gijón y trabajamos con clientes nacionales e internacionales.", result.description
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
    end
  end

  test "a website does not exist" do
    VCR.use_cassette("analysis/website_info/does_not_exist") do
      info = Analysis::WebsiteInfo.new(url: "https://not_existing_website_12345.gg/")
      assert info.perform_and_save

      assert_equal "Failed to fetch the page https://not_existing_website_12345.gg/ after 3 attempts", info.error
    end
  end
end
