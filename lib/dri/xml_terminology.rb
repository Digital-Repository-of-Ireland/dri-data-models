# frozen_string_literal: true
#
# A minimal, in-house replacement for the parts of `om` that qdc.rb / mods.rb /
# marc.rb / ead.rb / ead_component.rb actually use:
#   - t.root(path: ...)
#   - t.foo(namespace_prefix: ..., path: ..., index_as: [...]) { nested terms }
#   - attribute-subterms:  t.foo_lang(path: { attribute: 'xml:lang' })
#   - t.bar(ref: :foo, attributes: { 'xsi:type' => '...' })
#   - t.baz(proxy: [:foo, :foo_lang])
#   - dynamically-generated terms via `t.send("role_#{x}", ...)`

require 'nokogiri'

module DRI
  module XmlTerminology
    autoload :Term, 'dri/xml_terminology/term'
    autoload :Terminology, 'dri/xml_terminology/terminology'
    autoload :TermBuilder, 'dri/xml_terminology/term_builder'
    autoload :Evaluator, 'dri/xml_terminology/evaluator'
    autoload :NodeScope, 'dri/xml_terminology/node_scope'
    autoload :NodeBuilder, 'dri/xml_terminology/node_builder'
    autoload :SolrIndexer, 'dri/xml_terminology/solr_indexer'
  end
end
