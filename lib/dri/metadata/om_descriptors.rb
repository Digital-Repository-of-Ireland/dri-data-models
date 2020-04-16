require 'solrizer'

# DRI namespace
module DRI
  # Metadata namespace
  module Metadata
    # Implements helper methods for metadata indexing using Solrizer. Methods mostly used in OM terminologies
    class OmDescriptors
      require 'iso-639'

      # Creates a facet index in SOLR for ISO 639.2 language codes
      def self.language_facetable
        @language ||= ::Solrizer::Descriptor.new(:string, :indexed, :multivalued,
                                               converter: DRI::Metadata::Descriptors.language_converter)
      end

      # Creates a searchable index in SOLR
      def self.cleaned_searchable
        @searchable ||= ::Solrizer::Descriptor.new(::Solrizer::DefaultDescriptors.stored_searchable_field_definition,
                                                 converter: DRI::Metadata::Descriptors.input_converter,
                                                 requires_type: true)
      end

      # Creates a cleaned, displayable index in Solr
      def self.cleaned_displayable
        @displayable ||= ::Solrizer::Descriptor.new(:string, :indexed, :multivalued,
                                                  converter: DRI::Metadata::Descriptors.input_converter)
      end

      # Creates a facet index in SOLR
      def self.cleaned_facetable
        @facetable ||= ::Solrizer::Descriptor.new(:string, :indexed, :multivalued,
                                                converter: DRI::Metadata::Descriptors.facet_converter)
      end
    end
  end
end
