module Analysis
  def self.table_name_prefix
    "analysis_"
  end

  TWO_LETTER_CODE = {
    eng: "en",
    spa: "es",
    deu: "de",
    fra: "fr"
  }

  DEFAULT_LANGUAGE = :eng

  SUPPORTED_LANGUAGES = %i[spa eng deu fra]

  LANGUAGE_NAMES_IN_ENGLISH = {
    eng: "English",
    spa: "Spanish",
    deu: "German",
    fra: "French"
  }

  LANGUAGE_NAMES_IN_LANGUAGE = {
    eng: "English",
    spa: "Español",
    deu: "Deutsch",
    fra: "Français"
  }
end
