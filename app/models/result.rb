class Result < ApplicationRecord
  belongs_to :report

  def html_safe
    JSON.parse(json)["value"].html_safe
  end
end
