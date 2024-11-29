class AddLatestErrorToReports < ActiveRecord::Migration[8.0]
  def change
    add_column :reports, :latest_error, :text
  end
end
