class CreateAnalysis < ActiveRecord::Migration[8.0]
  def change
    create_table :analyses, id: false do |t|
      t.ksuid_binary :id, primary_key: true
      t.string :status, null: false, default: "pending"
      t.timestamps
    end

    create_table :analysis_steps do |t|
      t.string :type, null: false
      t.json :input
      t.json :result
      t.string :error
      t.integer :attempt, null: false, default: 1

      t.ksuid_binary :analysis_id, null: false
      t.timestamps
    end

    add_index :analysis_steps, [ :analysis_id, :type ], unique: true
  end
end
