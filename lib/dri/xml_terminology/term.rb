# frozen_string_literal: true

module DRI
  module XmlTerminology
    # One node in the terminology tree.
    class Term
      attr_reader :name, :path, :namespace_prefix, :attributes, :ref, :proxy,
                  :index_as, :children

      def initialize(name, opts = {})
        @name             = name.to_sym
        @path             = opts[:path]                # String, Hash (attribute), or nil
        @namespace_prefix = opts[:namespace_prefix]
        @attributes       = opts[:attributes] || {}     # e.g. {'xsi:type' => 'dcterms:URI'}
        @ref              = normalize_ref(opts[:ref])   # term name this is an alias/filter of
        @proxy            = opts[:proxy]                # [:term_a, :term_b] chain
        @index_as         = opts[:index_as] || []       # Descriptor objects/symbols, see SolrIndexer
        @children         = {}
      end

      def attribute_term?
        path.is_a?(Hash) && path[:attribute]
      end

      # The local element/attribute name to look for, if `path` doesn't
      # already spell out a full XPath fragment (e.g. 'identifier[1]').
      def local_name
        return path[:attribute] if attribute_term?

        path || name.to_s
      end

      # Same, but with any positional predicate ('identifier[1]') stripped,
      # for use when *creating* a brand-new element.
      def build_element_name
        local_name.to_s.sub(/\[.*\]\z/, '')
      end

      # True when `path` is already a complete, multi-segment (or unioned)
      # XPath fragment someone wrote by hand -- e.g.
      #   'mods/mods:name[mods:role/mods:roleTerm/@type="code"]/mods:namePart'
      #   '//mods:mods/mods:abstract | //mods:mods[not(mods:abstract)]/mods:note'
      # Kept only as a documentation flag now.
      def compound_path?
        path.is_a?(String) && path.match?(%r{[/|]})
      end

      # Build the XPath fragment for *this* term, relative to its parent
      # context node.
      #
      def relative_xpath
        return "@#{local_name}" if attribute_term?

        base = namespace_prefix ? "#{namespace_prefix}:#{local_name}" : local_name.to_s
        return base if attributes.empty?

        predicate = attributes.map { |k, v| attribute_predicate(k, v) }.join(' and ')
        "#{base}[#{predicate}]"
      end

      private

      # OM convention: an attribute value of the symbol `:none` means "this
      # attribute must be ABSENT", not the literal string 'none'. Used
      # throughout mods.rb/ead.rb to pick out the base date/temporal element
      # from its point='start'/point='end' variants.
      def attribute_predicate(key, value)
        value == :none ? "not(@#{key})" : "@#{key}='#{value}'"
      end

      # `ref:` is sometimes given as a bare symbol (`ref: :temporal`) and
      # sometimes as a single- or multi-element array (`ref: [:role_term]`,
      # `ref: [:record, :controlfield]`) -- OM treats these as equivalent
      # "term pointers". If a future terminology has real name collisions across
      # nesting levels for a multi-element ref, this needs to walk the whole
      # chain the way `proxy` does, not just take the last element.
      def normalize_ref(ref)
        ref.is_a?(Array) ? ref.last : ref
      end
    end
  end
end
