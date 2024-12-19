class AddEnumToAnalysisStep < ActiveRecord::Migration[8.0]
  def change
    add_column :analysis_steps, :status, :string, default: "pending", null: false
    add_index :analysis_steps, [ :status, :type ]
  end
end
