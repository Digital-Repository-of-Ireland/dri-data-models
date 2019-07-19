class CreateDriReconciliationResults < ActiveRecord::Migration
  def change
    create_table :dri_reconciliation_results do |t|
      t.string :object_id
      t.string :uri

      t.timestamps null: false
    end
  end
end
