module Analysis
  def self.table_name_prefix
    "analysis_"
  end

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
