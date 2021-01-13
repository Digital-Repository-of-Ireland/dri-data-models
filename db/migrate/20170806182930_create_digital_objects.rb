class CreateDigitalObjects < ActiveRecord::Migration[4.2]
  def change
    create_table :dri_digital_objects do |t|
      t.string :ingest_files_from_metadata
      t.string :published_at
      t.string :digital_object_type
      t.references :governing_collection, polymorphic: true
      t.references :previous_sibling, polymorphic: true
      t.references :documentation_for, polymorphic: true
      t.timestamps
    end

    add_index :dri_digital_objects, [:governing_collection_type, :governing_collection_id], name: 'governing_index'
    add_index :dri_digital_objects, [:previous_sibling_type, :previous_sibling_id], name: 'sibling_index'
    add_index :dri_digital_objects, [:documentation_for_type, :documentation_for_id], name: 'doc_for_index'
  end
end
