# frozen_string_literal: true
class CreateGenericFiles < ActiveRecord::Migration[4.2]
  def change
    create_table :dri_generic_files do |t|
      t.text :title
      t.text :creator
      t.string :filename
      t.string :label
      t.string :depositor
      t.string :mime_type
      t.integer :version
      t.string :path
      t.string :checksum_md5
      t.string :checksum_sha256
      t.string :checksum_rmd160
      t.timestamps
      t.references :digital_object, polymorphic: true, index: { name: 'gf_do_idx' }
    end
  end
end
