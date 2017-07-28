# DRI namespace
module DRI
  # Metadata namespace
  module Metadata
    # Implements DRI Base metadata class from which the different DRI supported standards
    # metadata classes inherit from
    class Base < ::DRI::OmDatastream
      # Boolean flag for metadata types like EAD where extracts of the metadata
      # may be stored in other Fedora objects. This allows us to add functions
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

      # Returns an array with the values of a metadata field if present as an object's attribute
      # @param [String] field the name of the metadata field
      # @return [Array<String>] the array of field metadata values
      def metadata_path(field)
        # Generic check, if metadata class responds to fieldname then that's the path
        return [field] if respond_to? field

        []
      end

      # Remove null values from a given field within
      # the solr document for this object
      #
      # @param [Hash] solr_doc the solr document hash
      # @param [String] field the solr field key
      # @return [hash] the solr document hash
      def remove_null_values(solr_doc, field)
        [:stored_searchable, :facetable].each do |index_type|
          if solr_doc[ActiveFedora.index_field_mapper.solr_name(field, index_type)].present?
            solr_doc[ActiveFedora.index_field_mapper.solr_name(field, index_type)].delete_if{ |v| /^null$/i.match(v) || (!v.nil? && v.empty?) }
          end
        end

        solr_doc
      end
    end
  end
end
