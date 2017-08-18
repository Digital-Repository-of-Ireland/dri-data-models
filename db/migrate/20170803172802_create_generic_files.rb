class CreateGenericFiles < ActiveRecord::Migration
  def change
    create_table :generic_files do |t|
      t.text :title
      t.text :creator
      t.string :label
      t.string :depositor
      t.string :mime_type
      t.integer :version
      t.string :path
      t.string :checksum_md5
      t.string :checksum_sha256
      t.string :checksum_rmd160
      t.timestamps
      t.references :bases, index: true, foreign_key: true
    end
  end
end
