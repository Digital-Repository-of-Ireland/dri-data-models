# frozen_string_literal: true

require 'dri/metadata/solr_descriptor'

module DRI
  module Metadata
    # Replaces the original `solrizer`-dependent DRI::Metadata::Descriptors.
    # Kept at the same constant path and with the same method names because
    # the real terminology files (qdc.rb, mods.rb, marc.rb, ead.rb,
    # ead_component.rb) call `DRI::Metadata::Descriptors.cleaned_searchable`
    # etc. directly, as literal Ruby code, when they're loaded -- this has
    # to exist and behave the same way, or those files won't load at all.
    #
    # Suffix + converter for each method here were confirmed against the
    # real `solrizer` gem's source (Descriptor#name_and_converter,
    # Suffix#to_s, DefaultDescriptors) -- see
    # DRI::XmlTerminology::SolrIndexer for the full writeup of what was
    # verified and why the type-inference machinery real Solrizer has isn't
    # needed here.
    class Descriptors
      def self.cleaned_searchable
        @cleaned_searchable ||= SolrDescriptor.new(suffix: '_tesim', multivalued: true, converter: method(:input_converter))
      end

      def self.cleaned_displayable
        @cleaned_displayable ||= SolrDescriptor.new(suffix: '_sim', multivalued: true, converter: method(:input_converter))
      end

      def self.cleaned_facetable
        @cleaned_facetable ||= SolrDescriptor.new(suffix: '_sim', multivalued: true, converter: method(:facet_converter))
      end

      def self.language_facetable
        @language_facetable ||= SolrDescriptor.new(suffix: '_sim', multivalued: true, converter: method(:language_converter))
      end

      def self.stored_searchable
        @stored_searchable ||= SolrDescriptor.new(suffix: '_tesim', multivalued: true)
      end

      def self.stored_sortable
        @stored_sortable ||= SolrDescriptor.new(suffix: '_ssi', multivalued: false)
      end

      def self.sortable
        @sortable ||= SolrDescriptor.new(suffix: '_si', multivalued: false)
      end
      # ----- value converters (behavior matches the original exactly) -----

      def self.input_converter(val)
        clean = val.to_s.strip
        return 'N/A' if clean.casecmp('n/a').zero?

        clean.empty? ? nil : clean
      end

      def self.facet_converter(val)
        clean = val.to_s.strip
        return nil if clean.empty? || clean.casecmp('n/a').zero?

        clean
      end

      def self.language_converter(val)
        standardise_language_code(val)
      rescue StandardError, LoadError
        nil
      end

      # Same ISO 639.2 standardization as the original -- still needs the
      # (non-deprecated) `iso-639` gem. If you'd rather drop it too, this is
      # the one place to swap in a simpler mapping.
      def self.standardise_language_code(val)
        require 'iso-639'
        clean_val = val.to_s.strip.split(/-|_/)[0].strip.downcase
        result = ISO_639.find(clean_val) || ISO_639.find_by_english_name(clean_val.capitalize)
        result&.alpha3_bibliographic
      end
    end
  end
end
