module Analysis
  def self.table_name_prefix
    "analysis_"
  end

  TWO_LETTER_CODE = {
    eng: "en",
    spa: "es",
    deu: "de",
    fra: "fr",
    ita: "it"
  }.with_indifferent_access.freeze

  DEFAULT_LANGUAGE = :eng

  SUPPORTED_LANGUAGES = %i[spa eng deu fra ita]

  LANGUAGE_NAMES_IN_ENGLISH = {
    eng: "English",
    spa: "Spanish",
    deu: "German",
    fra: "French",
    ita: "Italian"
  }.with_indifferent_access.freeze

  LANGUAGE_NAMES_IN_LANGUAGE = {
    eng: "English",
    spa: "Español",
    deu: "Deutsch",
    fra: "Français",
    ita: "Italiano"
  }.with_indifferent_access.freeze
end
