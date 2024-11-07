# frozen_string_literal: true
class CreateDRIReconciliationResults < ActiveRecord::Migration[4.2]
  def change
    create_table :dri_reconciliation_results do |t|
      t.string :object_id
      t.string :uri

      t.timestamps null: false
    end
  end
end
