# DRI namespace
module DRI
  # ModelSupport namespace
  module ModelSupport
    # Includes the AF properties for DRI properties metadata
    module Properties
      extend ActiveSupport::Concern

      included do
        has_subresource :dri_properties, class_name: 'DRI::Metadata::Properties'

        delegate :object_type,:object_type=, to: :dri_properties
        delegate :depositor=, to: :dri_properties
        delegate :metadata_md5=, to: :dri_properties
        delegate :model_version=, to: :dri_properties
        delegate :verified=, to: :dri_properties
        delegate :doi=, to: :dri_properties
        delegate :cover_image=, to: :dri_properties
        delegate :institute,:institute=, to: :dri_properties
        delegate :depositing_institute=, to: :dri_properties
        delegate :licence=, to: :dri_properties
        delegate :ingest_files_from_metadata=, to: :dri_properties
        delegate :master_file_access=, to: :dri_properties
        delegate :published_at=, to: :dri_properties
        delegate :object_version=, to: :dri_properties
        delegate :status=, to: :dri_properties
      end

      def cover_image
        dri_properties.cover_image.first
      end

      def depositor
        dri_properties.depositor.first
      end

      def depositing_institute
        dri_properties.depositing_institute.first
      end

      def doi
        dri_properties.doi.first
      end

      def object_version
        dri_properties.object_version.first
      end

      def licence
        dri_properties.licence.first
      end

      def metadata_md5
        dri_properties.metadata_md5.first
      end

      def model_version
        dri_properties.model_version.first
      end

      # Returns whether the object has a status of 'published'
      #
      # @return [Boolean] true if status is published
      def published?
        status == 'published'
      end

      def published_at
        dri_properties.published_at.first if dri_properties.published_at.present?
      end

      def ingest_files_from_metadata
        dri_properties.ingest_files_from_metadata.first
      end

      def institute
        dri_properties.institute.first
      end

      def master_file_access
        dri_properties.master_file_access.first
      end

      def status
        dri_properties.status.first
      end

      def verified
        dri_properties.verified.first
      end
    end
  end
end
