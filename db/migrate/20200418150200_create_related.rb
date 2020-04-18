class CreateRelated < ActiveRecord::Migration[4.2]
  def change
    create_table :dri_related do |t|
      t.timestamps
    end
  end
end
