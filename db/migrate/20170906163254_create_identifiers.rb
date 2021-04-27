# frozen_string_literal: true
class CreateIdentifiers < ActiveRecord::Migration[4.2]
  def change
    create_table :dri_identifiers do |t|
      t.string :alternate_id
      t.references :identifiable, polymorphic: true
    end

    add_index :dri_identifiers, :alternate_id, unique: true
    add_index :dri_identifiers, [:identifiable_type, :identifiable_id]    
  end
end
