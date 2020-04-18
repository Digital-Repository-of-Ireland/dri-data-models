class AddPreservationOnlyToGenericFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :dri_generic_files, :preservation_only, :boolean
  end
end
