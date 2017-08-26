class AddNoidToDigitalObjects < ActiveRecord::Migration
  def change
    add_column :digital_objects, :noid, :string

    add_index :digital_objects, :noid, unique: true
  end
end
