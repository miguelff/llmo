class CreateReportOwners < ActiveRecord::Migration[8.0]
  def up
    Report.destroy_all

    add_reference :reports, :owner, polymorphic: true, null: false

    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :avatar
      t.timestamps
    end
  end

  def down
    remove_reference :reports, :owner, polymorphic: true
    drop_table :users
  end
end
