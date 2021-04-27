# frozen_string_literal: true
class CreateCollectionRelationships < ActiveRecord::Migration[5.2]
  def change
    create_table :dri_collection_relationships do |t|
      t.integer :digital_object_id
      t.integer :collection_relative_id
      t.timestamps
    end
  end
end
