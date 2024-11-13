class CreateReportOwners < ActiveRecord::Migration[8.0]
  def up
    Report.destroy_all

    add_reference :reports, :owner, polymorphic: true, null: false, index: false
    ActiveRecord::Base.connection.execute("CREATE INDEX index_reports_on_owner_and_created_at ON reports (owner_type, owner_id, created_at DESC)")

    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :avatar
      t.timestamps
    end

    add_index :users, :email, unique: true
  end

  def down
    remove_index :reports, name: 'index_reports_on_owner_and_created_at'
    remove_reference :reports, :owner, polymorphic: true
    drop_table :users
  end
end
