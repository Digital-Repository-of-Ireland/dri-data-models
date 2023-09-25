class ChangeTypeOfInstituteColumn < ActiveRecord::Migration[6.1]
  def change
    change_column :dri_digital_objects, :institute, :text
  end
end
