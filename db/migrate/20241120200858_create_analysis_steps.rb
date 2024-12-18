class CreateAnalysisSteps < ActiveRecord::Migration[8.0]
  def change
    create_table :analysis_steps do |t|
      t.string :type   # STI column
      t.json :result
      t.string :provider, null: false, default: "openai"
      t.string :model, null: false, default: "gpt-4o-mini"
      t.float :temperature, null: false, default: 0.0
      t.string :error
      t.timestamps
      t.belongs_to :report, null: false, foreign_key: true, type: :binary, limit: 16
    end

    add_index :analysis_steps, [ :type, :report_id ]
  end
end
