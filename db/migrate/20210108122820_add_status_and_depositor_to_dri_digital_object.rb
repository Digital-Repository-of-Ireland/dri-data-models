# frozen_string_literal: true
class AddStatusAndDepositorToDRIDigitalObject < ActiveRecord::Migration[5.2]
  def change
    add_column :dri_digital_objects, :status, :string
    add_column :dri_digital_objects, :depositor, :string
  end
end
