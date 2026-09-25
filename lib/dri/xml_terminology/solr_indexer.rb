# frozen_string_literal: true

require 'dri/metadata/descriptors'

module DRI
  module XmlTerminology
    # Replaces OM::XML::TerminologyBasedSolrizer + deprecated `solrizer`
    # gem's generic indexing walk.
    #
    module SolrIndexer
      def self.to_solr(record, solr_doc = {})
        terminology = record.class.terminology
        return solr_doc if terminology.nil?

        terminology.terms.each_value do |term|
          next if term.index_as.nil? || term.index_as.empty?

          index_term(record, term, solr_doc)
        end
        solr_doc
      end

      def self.index_term(record, term, solr_doc)
        raw_values = record.evaluator.values_for(term.name)
        return if raw_values.empty?

        term.index_as.each do |descriptor|
          field = "#{term.name}#{descriptor.suffix}"
          insert(solr_doc, field, raw_values, descriptor)
        end
      end

      def self.insert(solr_doc, field, raw_values, descriptor)
        converted = raw_values.map { |v| descriptor.converter ? descriptor.converter.call(v) : v.to_s }.compact

        if descriptor.multivalued?
          values = (solr_doc[field] ||= [])
          converted.each { |v| values << v unless values.include?(v) }
        else
          solr_doc[field] = converted.last unless converted.empty?
        end
      end
    end
  end
end