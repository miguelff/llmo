class AddAttemptToAnalysisStep < ActiveRecord::Migration[8.0]
  def change
    add_column :analysis_steps, :attempt, :integer, default: 1
  end
end
