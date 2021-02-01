# frozen_string_literal: true
# DRI namespace
module DRI
  # ModelSupport namespace
  module ModelSupport
    # Includes properties, methods common to all metadata digital object classes
    module Common
      extend ActiveSupport::Concern

      included do
        has_one :alternate_identifier, class_name: 'DRI::Identifier', as: :identifiable
        # one-to-many AF relationship to associate digital assets with their object
        has_many :generic_files, class_name: 'DRI::GenericFile', inverse_of: :digital_object, dependent: :destroy
        # one-to-many AF relationship to associate documentation objects
        has_many :documentation_objects, class_name: 'DRI::Documentation', as: :documentation_for, dependent: :destroy
        # Complete metadata record datastream
        has_one :fullMetadata, class_name: 'DRI::Metadata::FullMetadata', as: :describable, autosave: true

        has_one :access_control, autosave: true

        # DRI Mandatory (M)
        # Title (collection-level)
        delegate :title, :title=, to: :descMetadata
        # Description (collection-level)
        delegate :description, :description=, to: :descMetadata
        # ADDED TYPE, it is compulsory
        # delegate :type, to: 'descMetadata', multiple: true
        # Rights (collection-level)
        delegate :rights, :rights=, to: :descMetadata
        # Creator (collection-level)
        delegate :creator, :creator=, to: :descMetadata

        # DRI Recommended (R)
        # Contributor
        delegate :contributor, :contributor=, to: :descMetadata
        # Publisher (collection-level, DRI pre-populated)
        delegate :publisher, :publisher=, to: :descMetadata
        # Subject (collection-level)
        delegate :subject, :subject=, to: :descMetadata
        # Language (collection-level)
        delegate :language, :language=, to: :descMetadata

        serialize :institute, Array

        validate :custom_validations
      end

      private

      def custom_validations
        return true unless descMetadata.class < DRI::Datastreams::OmDatastream

        results = descMetadata.custom_validations
        return true if results.empty?

        results.each { |key, value| errors.add(key, value) }

        false
      end # custom_validations
    end # module
  end # module
end # module
