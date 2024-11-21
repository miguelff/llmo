module Analysis
  def self.table_name_prefix
    "analysis_"
  end

  SUPPORTED_LANGUAGES = %i[spa eng]
  DEFAULT_LANGUAGE = :eng
end
