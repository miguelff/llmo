class CreateAnalysisSteps < ActiveRecord::Migration[8.0]
  def change
    create_table :analysis_steps do |t|
      t.string :type, null: false
      t.binary :analysis_id, limit: 16, null: false
      t.json :input
      t.json :result
      t.string :error
      t.integer :attempt, null: false, default: 1
      t.timestamps
    end

    add_index :analysis_steps, [ :analysis_id, :type ]
  end
end
