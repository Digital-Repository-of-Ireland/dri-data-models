module DRI
  module Metadata
    # Shared indexing helpers used by multiple metadata datastream classes
    # (Marc, Mods, QualifiedDublinCore). include this module (not extend) into anything
    # that responds to #ng_xml.
    module CommonIndexing
      def searchable_field(name, type: nil)
        type ? Solrizer.solr_name(name, :stored_searchable, type: type) : Solrizer.solr_name(name, :stored_searchable)
      end
 
      def facetable_field(name, type: nil)
        type ? Solrizer.solr_name(name, :facetable, type: type) : Solrizer.solr_name(name, :facetable)
      end
 
      def sortable_field(name, type:)
        Solrizer.solr_name(name, :stored_sortable, type: type)
      end

      # all_metadata - A SOLR index of all the text contained in the XML document
      # @return [String]
      def all_metadata_text
        ng_xml.xpath('//text()').each_with_object(String.new) { |node, str| str << node.text << ' ' }
      end

      # Populates solr_doc with a date range plus optional year/start/end
      # fields, derived from an already-transformed array of DCMI-range
      # strings.
      #
      # @param [Hash] solr_doc
      # @param [Array<String>] ranges already-transformed DCMI range strings
      # @param [String] range_field
      # @param [String] start_field
      # @param [String] end_field
      # @param [String, nil] year_field optional - not every date range indexes a distinct year array
      # @return [Hash] solr_doc
      def index_date_range!(solr_doc, ranges, range_field:, start_field:, end_field:, year_field: nil)
        return solr_doc if ranges.blank?

        solr_doc[range_field] = ranges

        years = DRI::Metadata::Transformations.date_range_years(ranges)
        solr_doc[year_field] = years if year_field
        solr_doc[start_field] = years.min
        solr_doc[end_field] = years.max

        solr_doc
      end
    end
  end
end
