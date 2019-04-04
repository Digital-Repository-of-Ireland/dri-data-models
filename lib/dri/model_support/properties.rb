# DRI namespace
module DRI
  # ModelSupport namespace
  module ModelSupport
    # Includes the AF properties for DRI properties metadata
    module Properties
      extend ActiveSupport::Concern

      included do
        has_subresource :properties, class_name: 'DRI::Metadata::Properties'

        delegate :object_type,:object_type=, to: :properties#, multiple: true
        delegate :depositor=, to: :properties#, multiple: false
        delegate :metadata_md5=, to: :properties#, multiple: false
        delegate :model_version=, to: :properties#, multiple: false
        delegate :verified=, to: :properties#, multiple: false
        delegate :doi=, to: :properties#, multiple: false
        delegate :cover_image=, to: :properties#, multiple: false
        delegate :institute,:institute=, to: :properties#, multiple: true
        delegate :depositing_institute=, to: :properties#, multiple: false
        delegate :licence=, to: :properties#, multiple: false
        delegate :ingest_files_from_metadata=, to: :properties#, multiple: false
        delegate :master_file_access=, to: :properties#, multiple: false
        delegate :published_at=, to: :properties#, multiple: false
        delegate :object_version=, to: :properties#, multiple: false
        delegate :status=, to: :properties
      end

      def cover_image
        properties.cover_image.first
      end

      def depositor
        properties.depositer.first
      end

      def depositing_institute
        properties.depositing_institute.first
      end

      def doi
        properties.doi.first
      end

      def object_version
        properties.object_version.first
      end

      def licence
        properties.licence.first
      end

      def metadata_md5
        properties.metadata_md5.first
      end

      def model_version
        properties.model_version.first
      end

      # Returns whether the object has a status of 'published'
      #
      # @return [Boolean] true if status is published
      def published?
        status == 'published'
      end

      def published_at
        properties.published_at.first if properties.published_at.present?
      end

      def ingest_files_from_metadata
        properties.ingest_files_from_metadata.first
      end

      def institute
        properties.institute.first
      end

      def master_file_access
        properties.master_file_access.first
      end

      def status
        properties.status.first
      end

      def verified
        properties.verified.first
      end
    end
  end
end
