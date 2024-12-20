module Analysis
  class StructuredValueType < ActiveModel::Type::Value
    def initialize(struct_type)
        @struct_type = struct_type
    end

    def type
        :jsonb
    end

    def cast(value)
      if value.is_a?(Hash)
        @struct_type.from_h(value)
      else
        super
      end
    end

    def deserialize(value)
      return nil unless value.present?
      cast(ActiveSupport::JSON.decode(value))
    end

    def serialize(value)
      return value unless value.respond_to?(:to_h)
      ActiveSupport::JSON.encode(value.to_h)
    end
  end

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

  class Record < ApplicationRecord
    self.table_name = "analyses"

    include ActiveRecord::KSUID[:id, binary: true]

    has_many :steps, class_name: "Analysis::Step", foreign_key: :analysis_id, dependent: :destroy
  end
end
