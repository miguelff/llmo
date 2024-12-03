class AddIndexOnReportsUpdatedAt < ActiveRecord::Migration[8.0]
  def change
    add_index :reports, [ :updated_at, :status ]
  end
end
