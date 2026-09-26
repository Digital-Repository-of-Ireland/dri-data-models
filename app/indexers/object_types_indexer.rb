# frozen_string_literal: true
class ObjectTypesIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} if resource.wrapped_object.is_a?(DRI::EadCollection) || resource.wrapped_object.is_a?(DRI::EadComponent)
    return {} unless resource.wrapped_object.respond_to?(:type)

    object_types = []

    resource.wrapped_object.type.each { |cat| object_types.push cat.split.map(&:capitalize) * ' ' }
    object_types.push('Unknown') if object_types.count < 1

    {
      'object_type_sim' => object_types,
      'object_type_ssm' => object_types,
      'type_sim' => resource.wrapped_object.type,
      'type_tesim' => resource.wrapped_object.type,
    }
  end
end
