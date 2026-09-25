# frozen_string_literal: true

module DRI
  module XmlTerminology
    # The full term tree for one metadata format, plus root path/namespace
    # bookkeeping needed for writes.
    class Terminology
      attr_reader :terms, :root_path, :namespaces

      def initialize
        @terms = {}
        @root_path = '/*'
        @namespaces = {} # prefix (String) => URI, needed when *creating* nodes
      end

      def all_terms
        @terms
      end

      # Needed by `om_datastream.rb`'s `update_indexed_attributes`
      # (`terminology.has_term?(*OM.destringify(term_pointer))`) and by
      # `EncodedArchivalDescription#method_missing`. Accepts one or more
      # name segments (only the first is actually meaningful here).
      def has_term?(*pointer)
        name = pointer.first.to_sym
        !terms[name].nil? || !find_nested(name, terms).nil?
      end

      private

      def find_nested(name, node_terms)
        node_terms.each_value do |t|
          return t if t.name == name

          found = find_nested(name, t.children)
          return found if found
        end
        nil
      end
    end
  end
end
