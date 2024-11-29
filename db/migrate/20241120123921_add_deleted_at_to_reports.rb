class AddDeletedAtToReports < ActiveRecord::Migration[8.0]
  def change
    add_column :reports, :deleted_at, :datetime, null: true
  end
end
