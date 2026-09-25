# frozen_string_literal: true

require 'dri/xml_terminology'

module DRI
  module Metadata
    # Replaces `include OM::XML::Document` in DRI::Datastreams::OmDatastream.
    #
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
            # After mutating the tree, reassign `ng_xml` to itself.
            define_method("#{name}=") do |val|
              result = evaluator.set_values(name, val)
              self.ng_xml = ng_xml
              result
            end
          end
        end

        def from_xml(xml = nil, tmpl = new)
          return tmpl if xml.nil?

          tmpl.ng_xml = xml.is_a?(Nokogiri::XML::Node) ? xml : Nokogiri::XML::Document.parse(xml)
          tmpl
        end
      end

      # Rebuilt fresh every call, deliberately not memoized -- see the
      # module note above for why.
      def evaluator
        DRI::XmlTerminology::Evaluator.new(self.class.terminology, ng_xml)
      end

      # --- thin aliases matching real om_datastream.rb's instance API ---
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