# DRI namespace
module DRI
  # ModelSupport namespace
  module ModelSupport
    # Includes AF properties, methods common to all metadata digital object classes
    module Common
      extend ActiveSupport::Concern

      included do
        # Complete metadata record datastream
        has_subresource :fullMetadata, class_name: 'DRI::Metadata::FullMetadata'

        # one-to-many AF relationship to associate digital assets with their batch object
        has_many :generic_files, class_name: 'DRI::GenericFile', predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, dependent: :destroy
        # one-to-many AF relationship to associate documentation objects
        has_many :documentation_objects, class_name: 'DRI::Documentation', predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isDescriptionOf, as: :documentation_for

        # Declare a 'extracted' DS, of the following type
        # Unused for NOW
        has_subresource :extracted, class_name: 'DRI::Metadata::Extracted'

        # Declare the attributes of 'extracted' DS - 'full_text' - and that the DS is repeatable
        # Unused for NOW
        delegate :full_text, to: :extracted

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

        validate :custom_validations
      end

      private

      def custom_validations
        return true unless descMetadata.class < DRI::Metadata::Base

        results = descMetadata.custom_validations
        return true if results.empty?

        results.each { |key, value| errors.add(key, value) }

        false
      end # custom_validations
    end # module
  end # module
end # module
