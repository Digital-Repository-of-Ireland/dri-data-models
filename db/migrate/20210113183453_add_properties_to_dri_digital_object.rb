# frozen_string_literal: true
class AddPropertiesToDriDigitalObject < ActiveRecord::Migration[5.2]
  def change
    add_column :dri_digital_objects, :model_version, :string
    add_column :dri_digital_objects, :verified, :string
    add_column :dri_digital_objects, :doi, :string
    add_column :dri_digital_objects, :cover_image, :string
    add_column :dri_digital_objects, :institute, :string
    add_column :dri_digital_objects, :depositing_institute, :string
    add_column :dri_digital_objects, :licence, :string
  end
end
