# frozen_string_literal: true
class CreateOmDatastreams < ActiveRecord::Migration[4.2]
  def change
    create_table :dri_om_datastreams do |t|
      t.string  :type
      t.binary  :datastream_content
      t.references :describable, polymorphic: true, index: { name: 'om_index' }
      t.timestamps 
   end
  end
end
