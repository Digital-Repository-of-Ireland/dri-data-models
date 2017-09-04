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
      t.string :discover_users
      t.string :discover_groups
      t.string :read_users
      t.string :read_groups
      t.string :edit_users
      t.string :edit_groups
      t.string :manager_users
      t.string :manager_groups
      t.timestamps
      t.references :digital_object, polymorphic: true 
    end

    add_index :generic_files, [:digital_object_type, :digital_object_id], name: 'gf_do_index'
  end
end
