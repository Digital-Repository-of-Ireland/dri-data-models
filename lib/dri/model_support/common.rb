# DRI namespace
module DRI
  # ModelSupport namespace
  module ModelSupport
    # Includes AF properties, methods common to all metadata digital object classes
    module Common
      extend ActiveSupport::Concern

      included do
        # one-to-many AF relationship to associate digital assets with their object
        has_many :generic_files, class_name: 'DRI::GenericFile', inverse_of: :digital_object, dependent: :destroy
        # one-to-many AF relationship to associate documentation objects
        has_many :documentation_objects, class_name: 'DRI::Documentation', as: :documentation_for, dependent: :destroy
        has_one :properties, class_name: 'DRI::Metadata::Properties', as: :describable, autosave: true        
        # Complete metadata record datastream
        has_one :fullMetadata, class_name: 'DRI::Metadata::FullMetadata', as: :describable, autosave: true

        # TODO: Check that these match the DRI Level 1 and 2 terms
        # DRI Mandatory (M)
        # Title (collection-level)
        delegate :title,:title=, to: :descMetadata
        # Description (collection-level)
        delegate :description,:description=, to: :descMetadata
        # ADDED TYPE, it is compulsory
        # delegate :type, to: 'descMetadata', multiple: true
        # Rights (collection-level)
        delegate :rights,:rights=, to: :descMetadata
        # Creator (collection-level)
        delegate :creator,:creator=, to: :descMetadata

        # DRI Recommended (R)
        # Contributor
        delegate :contributor,:contributor=, to: :descMetadata
        # Publisher (collection-level, DRI pre-populated)
        delegate :publisher,:publisher=, to: :descMetadata
        # Subject (collection-level)
        delegate :subject,:subject=, to: :descMetadata
        # Language (collection-level)
        delegate :language,:language=, to: :descMetadata

        delegate :status,:status=, to: :properties
        delegate :object_type,:object_type=, to: :properties
        delegate :depositor,:depositor=, to: :properties
        delegate :metadata_md5,:metadata_md5=, to: :properties
        delegate :model_version,:model_version=, to: :properties
        delegate :verified,:verified=, to: :properties
        delegate :doi,:doi=, to: :properties
        delegate :cover_image,:cover_image=, to: :properties
        delegate :institute,:institute=, to: :properties
        delegate :depositing_institute=, to: :properties
        delegate :licence,:licence=, to: :properties
        delegate :object_version=, to: :properties
        
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
