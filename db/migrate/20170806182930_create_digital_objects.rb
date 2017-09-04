class CreateDigitalObjects < ActiveRecord::Migration
  def change
    create_table :digital_objects do |t|
      t.string :ingest_files_from_metadata
      t.string :master_file_access
      t.string :published_at
      t.string :digital_object_type
      t.string :discover_users
      t.string :discover_groups
      t.string :read_users
      t.string :read_groups
      t.string :edit_users
      t.string :edit_groups
      t.string :manager_users
      t.string :manager_groups
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
