class AddVisibilityToAccessControls < ActiveRecord::Migration[6.1]
  def change
    add_column :dri_access_controls, :visibility, :string
  end
end
