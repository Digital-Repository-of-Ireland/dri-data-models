class AddStatusAndDepositorToDriDigitalObject < ActiveRecord::Migration[5.2]
  def change
    add_column :dri_digital_objects, :status, :string
    add_column :dri_digital_objects, :depositor, :string
  end
end
