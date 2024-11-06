class CreateReports < ActiveRecord::Migration[8.0]
  def change
    create_table :reports do |t|
      t.string :query, null: false
      t.json :advanced_settings
      t.integer :status, default: 0

      t.timestamps
    end

    add_index :reports, :status
    add_index :reports, :created_at
  end
end
