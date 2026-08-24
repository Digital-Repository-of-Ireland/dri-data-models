# frozen_string_literal: true
module DRI
  module Metadata
    autoload :Descriptors, 'dri/metadata/descriptors'
    autoload :EncodedArchivalDescription, 'dri/metadata/encoded_archival_description'
    autoload :EncodedArchivalDescriptionComponent, 'dri/metadata/encoded_archival_description_component'
    autoload :EadDateIndexing, 'dri/metadata/ead/ead_date_indexing'
    autoload :FullMetadata, 'dri/metadata/full_metadata'
    autoload :Mods, 'dri/metadata/mods'
    autoload :SolrIndexer, 'dri/metadata/mods/solr_indexer'
    autoload :TermsHashExtractor, 'dri/metadata/mods/terms_hash_extractor'
    autoload :Validator, 'dri/metadata/mods/validator'
    autoload :Extracted, 'dri/metadata/extracted'
    autoload :QualifiedDublinCore, 'dri/metadata/qualified_dublin_core'
    autoload :Transformations, 'dri/metadata/transformations'
    autoload :SpatialTransformations, 'dri/metadata/transformations/spatial_transformations'
    autoload :Marc, 'dri/metadata/marc'
    autoload :Terminologies, 'dri/metadata/terminologies'
    autoload :CommonIndexing, 'dri/metadata/common_indexing'

    # Boolean flag for metadata types like EAD where extracts of the metadata
    # may be stored in other objects. This allows us to add functions
    # to synchronize the XML between several objects
    # @see DRI::Metadata::EncodedArchivalDescription#synchronize_metadata_on_save
    # @see DRI::Metadata::EncodedArchivalDescriptionComponent#synchronize_metadata_on_save
    attr_accessor :synchronize_metadata_on_save

    # Determine whether the metadata spefies that this object is a collection
    # @return [Boolean] true if collection metadata record; false otherwise
    def collection?
      # Implement in subclasses
      false
    end

    # Default DRI specific metadata validations
    def custom_validations
      # Implemented in subclasses
      {}
    end

    def filter_uris(array)
      array.reject { |i| i[/\A#{URI.regexp(['http', 'https'])}\z/] }
    end

    # Returns an array with the values of a metadata field if present as an object's attribute
    # @param [String] field the name of the metadata field
    # @return [Array<String>] the array of field metadata values
    def metadata_path(field)
      # Generic check, if metadata class responds to fieldname then that's the path
      return [field] if respond_to? field

      []
    end

    def prefix(_path)
      ''
    end

    def reconciliation_uris
      return [] if describable.alternate_id.nil?
      DRI::ReconciliationResult.where(object_id: describable.alternate_id).pluck(:uri)
    end

    # Remove null values from a given field within
    # the solr document for this object
    #
    # @param [Hash] solr_doc the solr document hash
    # @param [String] field the solr field key
    # @return [hash] the solr document hash
    def remove_null_values(solr_doc, field)
      [:stored_searchable, :facetable].each do |index_type|
        solr_doc[Solrizer.solr_name(field, index_type)].delete_if { |v| /^null$/i.match(v) || (!v.nil? && v.empty?) } if solr_doc[Solrizer.solr_name(field, index_type)].present?
      end

      solr_doc
    end
  end
end
