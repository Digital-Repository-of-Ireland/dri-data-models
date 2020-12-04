# frozen_string_literal: true
class EadObjectTypesIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  # Indexing object types as a hierarchical tree
  def to_solr
    return {} unless resource.is_a?(DRI::EadCollection) || resource.is_a?(DRI::EadComponent)
    solr_doc = {}
    # Add title metadata from parent collections
    object_types = []
    resource.resource_type.each do |curr_category|
      object_types.push(curr_category.split.map(&:capitalize) * ' ') unless curr_category.blank?
    end

    if object_types.empty?
      case resource.class.to_s
      when "DRI::EadComponent"
        object_types.push('Collection') if resource.collection?
        if resource.ead_level.include? 'otherlevel'
          object_types.push(resource.ead_level_other.split.map(&:capitalize) * ' ')
        else
          object_types.push(resource.ead_level.split.map(&:capitalize) * ' ')
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
