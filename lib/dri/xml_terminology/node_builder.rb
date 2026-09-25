# frozen_string_literal: true

module DRI
  module XmlTerminology
    # Creates a new Nokogiri element for a term, with the right namespace
    # and attributes, declaring the namespace on the document root the
    # first time it's needed.
    class NodeBuilder
      def initialize(terminology, doc)
        @terminology = terminology
        @doc = doc
      end

      def create_element(term, value, attrs)
        ns_object = ensure_namespace!(term.namespace_prefix)
        node = Nokogiri::XML::Node.new(term.build_element_name, @doc)
        node.namespace = ns_object if ns_object
        node.content = value
        attrs.each { |k, v| set_attribute(node, k, v) unless v == :none }
        node
      end

      private

      def set_attribute(node, qualified_name, value)
        # Term#attributes keys are sometimes Symbols (`{ type: 'local' }`,
        # common in mods.rb/ead.rb) and sometimes Strings with an explicit
        # namespace prefix (`{ 'xsi:type' => 'dcterms:URI' }`, qdc.rb/mods.rb).
        # Coerce once here rather than assuming either shape.
        qualified_name = qualified_name.to_s
        ensure_namespace!(qualified_name.split(':').first) if qualified_name.include?(':')
        node[qualified_name] = value
      end

      # Declares (if needed) and returns the Nokogiri::XML::Namespace object
      # for a prefix, or nil for none.
      #
      # `'oxns'` is real om's synthetic alias for "the root's default
      # namespace" -- it's not a literal prefix that should ever appear in 
      # the document. If the document already declares a default (unprefixed) 
      # namespace for that URI, reuse it, so a newly-created element looks exactly
      # like the rest of the document (`<fileinfo>`, not `<oxns:fileinfo>`). Only
      # declare a NEW `xmlns:oxns="..."` binding as a last resort, when
      # nothing already provides that URI.
      def ensure_namespace!(prefix)
        return nil unless prefix

        if prefix == 'oxns'
          uri = @terminology.namespaces['oxns']
          existing_default = @doc.root.namespace_definitions.find { |n| n.prefix.nil? && n.href == uri }
          return existing_default if existing_default

          existing_oxns = @doc.root.namespace_definitions.find { |n| n.prefix == 'oxns' }
          return existing_oxns if existing_oxns

          raise "Default namespace isn't registered -- add `xmlns: 'URI'` to `t.root(...)`" unless uri

          return @doc.root.add_namespace_definition('oxns', uri)
        end

        existing = @doc.root.namespace_definitions.find { |n| n.prefix == prefix }
        return existing if existing

        uri = @terminology.namespaces[prefix]
        raise "Namespace prefix '#{prefix}' isn't registered -- add `t.namespace('#{prefix}', 'URI')` " \
              "to the terminology" unless uri

        @doc.root.add_namespace_definition(prefix, uri)
      end
    end
  end
end