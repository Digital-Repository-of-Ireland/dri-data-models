# frozen_string_literal: true
class CreateLinkedData < ActiveRecord::Migration[4.2]
  def change
    create_table :dri_linked_data do |t|
      t.text :title
      t.string :creator
      t.string :resource_type
      t.string :identifier
      t.string :source
      t.text :spatial
      t.timestamps
    end
  end
end
