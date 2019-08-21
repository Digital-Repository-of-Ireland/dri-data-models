# DRI namespace
module DRI
  # ModelSupport namespace
  module ModelSupport
    # Includes the AF properties for DRI properties metadata
    module Properties
      extend ActiveSupport::Concern

      included do
        has_subresource :object_properties, class_name: 'DRI::Metadata::Properties'

        delegate :object_type,:object_type=, to: :object_properties
        delegate :depositor=, to: :object_properties
        delegate :metadata_md5=, to: :object_properties
        delegate :model_version=, to: :object_properties
        delegate :verified=, to: :object_properties
        delegate :doi=, to: :object_properties
        delegate :cover_image=, to: :object_properties
        delegate :institute,:institute=, to: :object_properties
        delegate :depositing_institute=, to: :object_properties
        delegate :licence=, to: :object_properties
        delegate :ingest_files_from_metadata=, to: :object_properties
        delegate :master_file_access=, to: :object_properties
        delegate :published_at=, to: :object_properties
        delegate :object_version=, to: :object_properties
        delegate :status=, to: :object_properties
      end

      def cover_image
        object_properties.cover_image.first
      end

      def depositor
        object_properties.depositor.first
      end

      def depositing_institute
        object_properties.depositing_institute.first
      end

      def doi
        object_properties.doi.first
      end

      def object_version
        object_properties.object_version.first
      end

      def licence
        object_properties.licence.first
      end

      def metadata_md5
        object_properties.metadata_md5.first
      end

      def model_version
        object_properties.model_version.first
      end

      # Returns whether the object has a status of 'published'
      #
      # @return [Boolean] true if status is published
      def published?
        status == 'published'
      end

      def published_at
        object_properties.published_at.first if object_properties.published_at.present?
      end

      def ingest_files_from_metadata
        object_properties.ingest_files_from_metadata.first
      end

      def institute
        object_properties.institute.first
      end

      def master_file_access
        object_properties.master_file_access.first
      end

      def status
        object_properties.status.first
      end

      def verified
        object_properties.verified.first
      end
    end
  end
end
