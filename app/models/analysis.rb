module Analysis
  def self.table_name_prefix
    "analysis_"
  end

  TWO_LETTER_CODE = {
    eng: "en"
  }.with_indifferent_access.freeze

  DEFAULT_LANGUAGE = :eng

  SUPPORTED_LANGUAGES = %i[eng]

  LANGUAGE_NAMES_IN_ENGLISH = {
    eng: "English"
  }.with_indifferent_access.freeze

  LANGUAGE_NAMES_IN_LANGUAGE = {
    eng: "English"
  }.with_indifferent_access.freeze
end
