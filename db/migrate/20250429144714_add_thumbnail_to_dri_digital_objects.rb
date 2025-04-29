class AddThumbnailToDRIDigitalObjects < ActiveRecord::Migration[7.1]
  def change
    add_column :dri_digital_objects, :thumbnail, :string
  end
end
