class CreateDigitalObjects < ActiveRecord::Migration
  def change
    create_table :digital_objects do |t|
      t.string :ingest_files_from_metadata
      t.string :master_file_access
      t.string :published_at
      t.string :type
      t.string :read_users_string
      t.string :read_groups_string
      t.string :edit_users_string
      t.string :edit_groups_string
      t.string :manager_users_string
      t.string :manager_groups_string
      t.references :governing_collection, polymorphic: true
      t.references :previous_sibling, polymorphic: true
      t.references :documentation_for, polymorphic: true
      t.timestamps
    end

    add_index :digital_objects, [:governing_collection_type, :governing_collection_id], name: 'governing_index'
    add_index :digital_objects, [:previous_sibling_type, :previous_sibling_id], name: 'sibling_index'
    add_index :digital_objects, [:documentation_for_type, :documentation_for_id], name: 'doc_for_index'
  end
end
