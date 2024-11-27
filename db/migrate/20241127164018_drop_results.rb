class DropResults < ActiveRecord::Migration[8.0]
  def change
    drop_table :results
  end
end
