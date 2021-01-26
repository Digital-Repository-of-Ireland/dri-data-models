# frozen_string_literal: true
class AddMetadataChecksumToDigitalObjects < ActiveRecord::Migration[5.2]
  def change
    add_column :dri_digital_objects, :metadata_checksum, :string

    add_index :dri_digital_objects, [:metadata_checksum], name: 'metadata_chksm_index'
  end
end
