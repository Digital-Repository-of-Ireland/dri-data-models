# DRI namespace
module DRI
  # ModelSupport namespace
  module ModelSupport
    # Includes the DRI properties metadata
    module Properties
      extend ActiveSupport::Concern

      class_methods do
        def dangerous_attribute_method?(method_name)
          return false if method_name == :properties
          super
        end
      end

      included do
        has_one :properties, class_name: 'DRI::Metadata::Properties', as: :describable, autosave: true

        delegate :object_type,:object_type=, to: :properties
        delegate :depositor=, to: :properties
        delegate :model_version=, to: :properties
        delegate :verified=, to: :properties
        delegate :doi=, to: :properties
        delegate :cover_image=, to: :properties
        delegate :institute,:institute=, to: :properties
        delegate :depositing_institute=, to: :properties
        delegate :licence=, to: :properties
        delegate :ingest_files_from_metadata=, to: :properties
        delegate :master_file_access=, to: :properties
        delegate :published_at=, to: :properties
        delegate :object_version=, to: :properties
        delegate :status=, to: :properties
      end

      def cover_image
        properties.cover_image.first
      end

      def depositor
        properties.depositor.first
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
