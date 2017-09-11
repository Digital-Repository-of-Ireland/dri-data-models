class CreateIdentifiers < ActiveRecord::Migration
  def change
    create_table :identifiers do |t|
      t.string :alternate_id
      t.references :identifiable, polymorphic: true
    end

    add_index :identifiers, :alternate_id, unique: true
    add_index :identifiers, [:identifiable_type, :identifiable_id]    
  end
end
