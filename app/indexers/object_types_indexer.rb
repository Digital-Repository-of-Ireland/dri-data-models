# frozen_string_literal: true
class ObjectTypesIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} if resource.is_a?(DRI::EadCollection) || resource.is_a?(DRI::EadComponent)
    return {} unless resource.respond_to?(:type)

    object_types = []

    resource.type.each { |cat| object_types.push cat.split.map(&:capitalize)*' ' }
    object_types.push('Unknown') if object_types.count < 1

    {
      'object_type_sim' => object_types,
      'object_type_ssm' => object_types,
      Solrizer.solr_name('type', DRI::Metadata::Descriptors.cleaned_facetable) => resource.type,
      Solrizer.solr_name('type', DRI::Metadata::Descriptors.cleaned_searchable) => resource.type,
      Solrizer.solr_name('type', DRI::Metadata::Descriptors.cleaned_displayable) => resource.type
    }
  end
end
