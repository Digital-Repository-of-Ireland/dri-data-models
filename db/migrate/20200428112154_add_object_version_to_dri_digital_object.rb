# frozen_string_literal: true
class AddObjectVersionToDriDigitalObject < ActiveRecord::Migration[5.2]
  def change
    add_column :dri_digital_objects, :object_version, :integer
  end
end
