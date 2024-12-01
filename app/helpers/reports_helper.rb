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

    def score_bar(term, score)
        <<-HTML.html_safe
        <dl>
            <dt class="text-sm font-medium text-gray-500 dark:text-gray-400"><h4 class="font-bold text-primary-500}">#{term}</h4></dt>
            <dd class="flex items-center mb-3">
                <div class="w-full bg-gray-200 rounded h-2.5 dark:bg-gray-700 me-2">
                    <div class="bg-blue-600 h-2.5 rounded dark:bg-primary-500" style="width: #{score * 10}%"></div>
                </div>
                <span class="text-sm font-medium text-gray-500 dark:text-gray-400">#{(score.to_i  / 2.0).round(1)}</span>
            </dd>
        </dl>
        HTML
    end

    def scores_tabbed_navigation(scores)
        content_tag(:div, class: "mb-4 border-b border-gray-200 dark:border-gray-700") do
            content_tag(:ul, class: "flex flex-wrap -mb-px text-sm font-medium text-center", id: "default-tab", data: { tabs_toggle: "#default-tab-content", "tabs-active-classes": "!text-primary-600 !border-primary-300", "inactive-classes": "!text-gray-500 !border-gray-200 dark:!text-gray-400 dark:!border-gray-700 " }, role: "tablist") do
                scores.keys.each_with_index.map do |key, index|
                    key_id = key.parameterize
                    content_tag(:li, class: "me-2", role: "presentation") do
                        content_tag(:button, key, class: "inline-block p-4 border-b-2 rounded-t-lg #{'hover:text-gray-600 hover:border-gray-300 dark:hover:text-gray-300' unless index == 0}", id: "#{key_id}-tab", data: { tabs_target: "##{key_id}" }, type: "button", role: "tab", aria: { controls: key_id, selected: index == 0 })
                    end
                end.join.html_safe
            end
        end +
        content_tag(:div, id: "default-tab-content") do
            scores.map.with_index do |(key, value), index|
                key_id = key.parameterize
                content_tag(:div, class: "flex flex-col #{'hidden' unless index == 0}", id: key_id, role: "tabpanel", aria: { labelledby: "#{key_id}-tab" }) do
                    value.map.with_index do |score, brand_index|
                        competitor = brand_index == 0 ? "#{score[:competitor]} (You)" : score[:competitor]
                        content_tag(:div, class: "grid grid-cols-1 lg:grid-cols-4 py-2 min-h-24 border-b border-gray-200 dark:border-gray-700") do
                            content_tag(:div, score_bar(competitor, score[:score].to_i), class: "col-span-1 px-4") +
                            content_tag(:div, content_tag(:p, score[:reason], class: "text-sm text-gray-500 dark:text-gray-400"), class: "col-span-3 px-4")
                        end
                    end.join.html_safe
                end
            end.reverse.join.html_safe
        end
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
