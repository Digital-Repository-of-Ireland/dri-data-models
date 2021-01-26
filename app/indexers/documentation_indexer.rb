# frozen_string_literal: true
class DocumentationIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless resource.wrapped_object.respond_to?(:documentation_for) && !resource.wrapped_object.documentation_for.nil?

    { 'isDescriptionOf_ssim' => [resource.wrapped_object.documentation_for.alternate_id] }
  end
end
