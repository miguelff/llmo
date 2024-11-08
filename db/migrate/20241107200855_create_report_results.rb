class CreateReportResults < ActiveRecord::Migration[8.0]
  def change
    create_table :results do |t|
      t.json :json
      t.belongs_to :report, null: false, foreign_key: true, type: :binary, limit: 16

      t.timestamps
    end
  end
end
