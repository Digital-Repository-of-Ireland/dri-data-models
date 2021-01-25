# frozen_string_literal: true
class EadObjectTypesIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  # Indexing object types as a hierarchical tree
  def to_solr
    return {} unless resource.wrapped_object.is_a?(DRI::EadCollection) || resource.wrapped_object.is_a?(DRI::EadComponent)
    solr_doc = {}
    # Add title metadata from parent collections
    object_types = []
    resource.wrapped_object.resource_type.each do |curr_category|
      object_types.push(curr_category.split.map(&:capitalize) * ' ') unless curr_category.blank?
    end

    if object_types.empty?
      case resource.wrapped_object.class.to_s
      when "DRI::EadComponent"
        object_types.push('Collection') if resource.wrapped_object.collection?
        if resource.wrapped_object.ead_level.include? 'otherlevel'
          object_types.push(resource.wrapped_object.ead_level_other.split.map(&:capitalize) * ' ')
        else
          object_types.push(resource.wrapped_object.ead_level.split.map(&:capitalize) * ' ')
        end
      when "DRI::EadCollection"
        object_types.push('Collection')
      end
    end

    object_types.push('Unknown') if object_types.count < 1

    solr_doc.merge!(
      {
        'object_type_sim' => object_types,
        'object_type_ssm' => object_types
      }
    )

    solr_doc
  end
end
