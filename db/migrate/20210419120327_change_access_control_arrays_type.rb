class ChangeAccessControlArraysType < ActiveRecord::Migration[5.2]
  def change
    change_column :dri_access_controls, :discover_users, :text
    change_column :dri_access_controls, :discover_groups, :text
    change_column :dri_access_controls, :read_users, :text
    change_column :dri_access_controls, :read_groups, :text
    change_column :dri_access_controls, :edit_users, :text
    change_column :dri_access_controls, :edit_groups, :text
    change_column :dri_access_controls, :manager_users, :text
    change_column :dri_access_controls, :manager_groups, :text
  end
end
