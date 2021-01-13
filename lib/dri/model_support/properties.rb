# DRI namespace
module DRI
  # ModelSupport namespace
  module ModelSupport
    # Includes the DRI properties metadata
    module Properties
      extend ActiveSupport::Concern

      included do
        has_one :properties, class_name: 'DRI::Metadata::Properties', as: :describable, autosave: true

        delegate :model_version=, to: :properties
        delegate :verified=, to: :properties
        delegate :doi=, to: :properties
        delegate :cover_image=, to: :properties
        delegate :institute,:institute=, to: :properties
        delegate :depositing_institute=, to: :properties
        delegate :licence=, to: :properties
      end

      def cover_image
        properties.cover_image.first
      end

      def depositing_institute
        properties.depositing_institute.first
      end

      def doi
        properties.doi.first
      end

      def licence
        properties.licence.first
      end

      def model_version
        properties.model_version.first
      end

      def institute
        properties.institute.first
      end

      def verified
        properties.verified.first
      end
    end
  end
end
