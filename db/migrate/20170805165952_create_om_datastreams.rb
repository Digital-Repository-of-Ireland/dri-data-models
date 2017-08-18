class CreateOmDatastreams < ActiveRecord::Migration
  def change
    create_table :om_datastreams do |t|
      t.string  :type
      t.binary  :datastream_content
      t.references :describable, polymorphic: true
      t.timestamps 
   end

  add_index :om_datastreams, [:describable_type, :describable_id], name: 'om_index'

  end
end
