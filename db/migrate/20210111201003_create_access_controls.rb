# frozen_string_literal: true
class CreateAccessControls < ActiveRecord::Migration[5.2]
  def change
    create_table :dri_access_controls do |t|
      t.string :master_file_access
      t.string :discover_users
      t.string :discover_groups
      t.string :read_users
      t.string :read_groups
      t.string :edit_users
      t.string :edit_groups
      t.string :manager_users
      t.string :manager_groups
      t.timestamps
      t.references :digital_object, polymorphic: true, index: { name: 'do_acl_idx' }
    end
  end
end
