# DRI namespace
module DRI
  # ModelSupport namespace
  module ModelSupport
    # Includes the AF properties for DRI properties metadata
    module Properties
      extend ActiveSupport::Concern

      included do
        has_subresource 'properties', class_name: 'DRI::Metadata::Properties'

        delegate :status, to: 'properties'#, multiple: false
        delegate :object_type, to: 'properties'#, multiple: true
        delegate :depositor, to: 'properties'#, multiple: false
        delegate :metadata_md5, to: 'properties'#, multiple: false
        delegate :model_version, to: 'properties'#, multiple: false
        delegate :verified, to: 'properties'#, multiple: false
        delegate :doi, to: 'properties'#, multiple: false
        delegate :cover_image, to: 'properties'#, multiple: false
        delegate :institute, to: 'properties'#, multiple: true
        delegate :depositing_institute=, to: 'properties'#, multiple: false
        delegate :licence, to: 'properties'#, multiple: false
        delegate :ingest_files_from_metadata,:ingest_files_from_metadata=, to: 'properties'#, multiple: false
        delegate :master_file_access, to: 'properties'#, multiple: false
        delegate :published_at=, to: 'properties'#, multiple: false
        delegate :object_version, to: 'properties'#, multiple: false
      end

      def depositing_institute
        depositing_institute.first if depositing_institute.present?
      end

      def published_at
        published_at.first if published_at.present?
      end

      def status
        status.first
      end

      def status=(status)
        self.status = status
      end
    end
  end
end
