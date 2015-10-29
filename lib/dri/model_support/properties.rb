module DRI
  module ModelSupport
    module Properties
      extend ActiveSupport::Concern

      included do
      	contains 'properties', class_name: 'DRI::Metadata::Properties'

        property :status, delegate_to: 'properties', multiple: false
        property :object_type, delegate_to: 'properties', multiple: true
        property :depositor, delegate_to: 'properties', multiple: false
        property :metadata_md5, delegate_to: 'properties', multiple: false
        property :model_version, delegate_to: 'properties', multiple: false
        property :verified, delegate_to: 'properties', multiple: false
        property :doi, delegate_to: 'properties', multiple: false
        property :cover_image, delegate_to: 'properties', multiple: false
        property :institute, delegate_to: 'properties', multiple: true
        property :depositing_institute, delegate_to: 'properties', multiple: false
        property :licence, delegate_to: 'properties', multiple: false
        property :ingest_files_from_metadata, delegate_to: 'properties', multiple: false
        property :master_file_access, delegate_to: 'properties', multiple: false
        property :published_at, delegate_to: 'properties', multiple: false
        property :object_version, delegate_to: 'properties', multiple: false
      end
    end
  end
end
