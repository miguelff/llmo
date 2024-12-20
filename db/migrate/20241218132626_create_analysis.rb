class CreateAnalysis < ActiveRecord::Migration[8.0]
  def change
    create_table :analyses do |t|
      t.string :status, null: false, default: "pending"
      t.string :uuid, null: false
      t.timestamps
    end

    create_table :analysis_steps do |t|
      t.string :type, null: false
      t.json :input
      t.json :result
      t.string :error
      t.integer :attempt, null: false, default: 1

      t.integer :analysis_id, null: false
      t.timestamps
    end

    add_index :analysis_steps, [ :analysis_id, :type ], unique: true
  end
end
