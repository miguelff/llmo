class AddNextActionToAnalysis < ActiveRecord::Migration[8.0]
  def change
    add_column :analyses, :next_action, :string, default: "your_website", null: false
  end
end
