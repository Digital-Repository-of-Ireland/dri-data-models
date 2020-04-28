# DRI namespace
module DRI
  # Metadata namespace
  module Metadata
    # Implements helper methods for metadata indexing using Solrizer. Methods mostly used in OM terminologies
    class Descriptors
      require 'iso-639'

      # Creates a facet index in SOLR for ISO 639.2 language codes
      def self.language_facetable
        @language ||= ::Solrizer::Descriptor.new(:string, :indexed, :multivalued,
                                               converter: language_converter)
      end

      # Creates a searchable index in SOLR
      def self.cleaned_searchable
        @searchable ||= ::Solrizer::Descriptor.new(::Solrizer::DefaultDescriptors.stored_searchable_field_definition,
                                                 converter: input_converter,
                                                 requires_type: true)
      end

      # Creates a cleaned, displayable index in Solr
      def self.cleaned_displayable
        @displayable ||= ::Solrizer::Descriptor.new(:string, :indexed, :multivalued,
                                                  converter: input_converter)
      end

      # Creates a facet index in SOLR
      def self.cleaned_facetable
        @facetable ||= ::Solrizer::Descriptor.new(:string, :indexed, :multivalued,
                                                converter: facet_converter)
      end

      # Converts an RFC 5646 or ISO 639.1 language code into an ISO 639.2 code
      def self.language_converter
        lambda do |_type|
          lambda do |val|
            begin
              standardise_language_code(val)
            rescue
              nil
            end
          end
        end
      end

      # Cleans the values of Solr Faceted fields
      def self.facet_converter
        lambda do |_type|
          lambda do |val|
            begin
              standardise_facet(val)
            rescue
              nil
            end
          end
        end
      end

      # Cleans the values of Solr displayable, searchable fields
      def self.input_converter
        lambda do |_type|
          lambda do |val|
            begin
              clean_val = val.strip

              return 'N/A' if clean_val.downcase == 'n/a'

              clean_val.empty? ? nil : clean_val
            rescue
              nil
            end
          end
        end
      end

      # Standardise facet values: capitalise, inserts nil if empty values
      # @param [String] val the facet value to index
      # @return [String] the cleaned value to index
      def standardise_facet(val = '')
        clean_val = val.strip

        return nil if clean_val.blank? || clean_val.downcase == 'n/a' || clean_val.empty?

        clean_val.capitalize
      end

      # Standardise language codes to be indexed RFC 5646, ISO_639.
      # @param [String] val the language code
      # @return [String] the converted language code to index
      def self.standardise_language_code(val = '')
        # If using RFC 5646, then val will be of the
        # format language-script-region-variant
        #
        # NOTE: RFC 5646 can be divided by either hyphens or
        # underscores.
        #
        # We really only care about the first element in this
        # format.
        clean_val = val.strip.split(/-|_/)[0].strip.downcase

        # Now we have either a ISO 639.1 code or ISO 639.2 code.
        result = ISO_639.find(clean_val)

        # If result is nil, as a last resort check if they wrote
        # the language name in english.
        result = ISO_639.find_by_english_name(clean_val.capitalize) if result.nil?

        return nil if result.nil?

        # Return the 3-letter ISO 639.2 code
        result.alpha3_bibliographic
      end
    end
  end
end
