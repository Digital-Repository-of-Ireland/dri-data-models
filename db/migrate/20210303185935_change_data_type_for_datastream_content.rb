class ChangeDataTypeForDatastreamContent < ActiveRecord::Migration[5.2]
  def change
    change_column :dri_om_datastreams, :datastream_content, :binary, limit: 16.megabyte
  end
end
