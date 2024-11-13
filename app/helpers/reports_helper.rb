module ReportsHelper
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
                "Countries",
                ISO3166::Country.all.map { |c| [ "#{c.emoji_flag} #{c.iso_short_name}", c.iso_short_name ] }
        ]
    ]
  end
end
