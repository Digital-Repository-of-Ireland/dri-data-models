# frozen_string_literal: true
class ObjectTypesIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    solr_doc = {}
    return solr_doc unless resource.respond_to?(:type)

    object_types = []

    resource.type.each { |cat| object_types.push cat.split.map(&:capitalize)*' ' }
    object_types.push('Unknown') if object_types.count < 1

    solr_doc.merge!('object_type_sim' => object_types)
    solr_doc.merge!('object_type_ssm' => object_types)

    solr_doc.merge!(Solrizer.solr_name('type', DRI::Metadata::Descriptors.cleaned_facetable) => resource.type)
    solr_doc.merge!(Solrizer.solr_name('type', DRI::Metadata::Descriptors.cleaned_searchable) => resource.type)
    solr_doc.merge!(Solrizer.solr_name('type', DRI::Metadata::Descriptors.cleaned_displayable) => resource.type)

    solr_doc
  end
end
