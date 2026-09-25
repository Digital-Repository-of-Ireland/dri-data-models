# frozen_string_literal: true

require 'dri/xml_terminology'

module DRI
  module Metadata
    # Replaces `include OM::XML::Document` in DRI::Datastreams::OmDatastream.
    #
    # Does NOT replace (see the note atop DRI::XmlTerminology::SolrIndexer
    # and DRI::XmlTerminology for what's covered vs. deliberately left out):
    #   - OM::XML::TerminologyBasedSolrizer (`to_solr`) -- see
    #     DRI::XmlTerminology::SolrIndexer for that half.
    #   - `update_values`/`update_indexed_attributes`'s term-POINTER
    #     addressing -- confirmed unused anywhere in the app.
    module TerminologySupport
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def set_terminology
          terminology = DRI::XmlTerminology::Terminology.new
          builder = DRI::XmlTerminology::TermBuilder.new(terminology)
          yield builder
          @terminology = terminology
          define_term_readers(all_term_names(terminology.terms))
        end

        def terminology
          @terminology
        end

        def all_term_names(terms)
          terms.each_value.flat_map { |t| [t.name] + all_term_names(t.children) }
        end

        def define_term_readers(names)
          names.each do |name|
            define_method(name) { |index = nil| index.nil? ? evaluator.values_for(name) : evaluator.node_at(name, index) }
            define_method("#{name}=") { |val| evaluator.set_values(name, val) }
          end
        end
      end

      def initialize(nokogiri_doc)
        @nokogiri_doc = nokogiri_doc
      end

      def ng_xml
        @nokogiri_doc
      end

      def ng_xml=(doc)
        doc = Nokogiri::XML(doc.is_a?(File) ? doc.read : doc) unless doc.is_a?(Nokogiri::XML::Document)
        @nokogiri_doc = doc
        @evaluator = nil
      end

      def evaluator
        @evaluator ||= DRI::XmlTerminology::Evaluator.new(self.class.terminology, @nokogiri_doc)
      end

      # --- thin aliases matching real om_datastream.rb's instance API ---

      # `term_values(*field_key)` in the real API; our readers already take
      # the term name directly (see ClassMethods#define_term_readers), so
      # this just dispatches to the generated reader for the first segment.
      # Only single-segment pointers are supported (see the module note).
      def term_values(*field_key)
        send(field_key.first)
      end

      alias get_values term_values

      def []=(name, value)
        send("#{name}=", value)
      end

      def find_by_terms(*termpointer)
        evaluator.raw_nodes_for(termpointer.first)
      end
    end
  end
end
