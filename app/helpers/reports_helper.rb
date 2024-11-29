module ReportsHelper
    def logo_url(brand)
        response = Faraday.get("https://api.logo.dev/search?q=#{brand}", nil, { "Authorization" => "Bearer: sk_ZcGYOz3AQBeYLzroGg3HUw" })
        logos = JSON.parse(response.body)
        logo = logos.find { |logo| logo["name"].casecmp?(brand) }
        logo ? logo["logo_url"] : nil
    end

    def logo_image(brand, css_classes: nil)
        logo_url(brand) ? image_tag(logo_url(brand), alt: "#{brand} logo", class: css_classes) : nil
    end

  def region_options
    [
        [
            "Any",
            [
                [ "🗺️ Any region", "any" ]
            ]
        ],
        [
        "Regions",
            [
                [ "🌎 North America (NA)", "north america" ],
                [ "🌍 Europe, Middle East & Africa (EMEA)", "europe, middle east & africa" ],
                [ "🌏 Asia Pacific (APAC)", "asia pacific" ],
                [ "🌎 Latin America (LATAM)", "latin america" ]
            ]
        ],
        [
            "Continents",
            [
                [ "🌎 North America", "north america" ],
                [ "🌎 South America", "south america" ],
                [ "🌍 Europe", "europe" ],
                [ "🌍 Africa", "africa" ],
                [ "🌏 Asia", "asia" ],
                [ "🌏 Oceania", "oceania" ]
            ]
        ],
        [
                "Countries",
                ISO3166::Country.all.sort_by { |c| c.iso_short_name }.map { |c| [ "#{c.emoji_flag} #{c.iso_short_name}", c.iso_short_name ] }
        ]
    ]
  end
end
