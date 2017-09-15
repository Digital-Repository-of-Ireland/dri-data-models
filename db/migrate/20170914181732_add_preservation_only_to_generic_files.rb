class AddPreservationOnlyToGenericFiles < ActiveRecord::Migration
  def change
    add_column :generic_files, :preservation_only, :boolean
  end
end
