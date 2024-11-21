module Analysis
  def self.table_name_prefix
    "analysis_"
  end

  SUPPORTED_LANGUAGES = %i[spa eng deu fra]
  DEFAULT_LANGUAGE = :eng
end
