class DropResults < ActiveRecord::Migration[8.0]
  def change
    Report.destroy_all
    drop_table :results
  end
end
