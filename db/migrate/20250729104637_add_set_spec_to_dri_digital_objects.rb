class AddSetSpecToDRIDigitalObjects < ActiveRecord::Migration[7.1]
  def change
    add_column :dri_digital_objects, :setspec, :text
  end
end
