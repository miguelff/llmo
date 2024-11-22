class CreateAnalysisQuestionAnswerings < ActiveRecord::Migration[8.0]
  def change
    create_table :analysis_question_answerings do |t|
      t.json :answers, null: false
      t.string :provider, null: false, default: "openai"
      t.string :model, null: false, default: "gpt-4o"
      t.float :temperature, null: false, default: 0.0
      t.string :error
      t.timestamps
      t.belongs_to :report, null: false, foreign_key: true, type: :binary, limit: 16
    end
  end
end