module DRI
  module ModelSupport
    module Properties
      extend ActiveSupport::Concern

      included do
      	contains "properties", class_name: "DRI::Metadata::Properties"

        has_attributes :status, datastream: :properties, multiple: false
        has_attributes :object_type, datastream: :properties, multiple: true
        has_attributes :depositor, datastream: :properties, multiple: false
        has_attributes :metadata_md5, datastream: :properties, multiple: false
        has_attributes :model_version, datastream: :properties, multiple: false
        has_attributes :verified, datastream: :properties, multiple: false
        has_attributes :doi, datastream: :properties, multiple: false
        has_attributes :cover_image, datastream: :properties, multiple: false
        has_attributes :institute, datastream: :properties, multiple: true
        has_attributes :depositing_institute, datastream: :properties, multiple: false
        has_attributes :licence, datastream: :properties, multiple: false
        has_attributes :ingest_files_from_metadata, datastream: :properties, multiple: false
        has_attributes :master_file_access, datastream: :properties, multiple: false
        has_attributes :published_at, datastream: :properties, multiple: false

      end
    end
  end
end
