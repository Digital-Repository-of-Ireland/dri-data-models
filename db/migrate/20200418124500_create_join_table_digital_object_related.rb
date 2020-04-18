class CreateJoinTableDigitalObjectRelated < ActiveRecord::Migration[5.0]
  def change
    create_join_table :digital_object, :related do |t|
      t.index [:digital_object_id, :related_id], name: 'do_related_idx'
      t.index [:related_id, :digital_object_id], name: 'rel_do_idx'
    end
  end
end

