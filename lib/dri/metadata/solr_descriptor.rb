# frozen_string_literal: true

module DRI
  module Metadata
    # Lightweight, `solrizer`-independent replacement for Solrizer::Descriptor.
    # Carries a fixed suffix rather than solrizer's type-inference machinery,
    # since every value produced by DRI::XmlTerminology's readers is always a
    # plain Ruby String
    SolrDescriptor = Struct.new(:suffix, :multivalued, :converter, keyword_init: true) do
      def multivalued? = multivalued
    end
  end
end
