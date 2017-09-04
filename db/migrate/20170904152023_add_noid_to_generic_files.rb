class AddNoidToGenericFiles < ActiveRecord::Migration
  def change
    add_column :generic_files, :noid, :string

    add_index :generic_files, :noid, unique: true
  end
end
