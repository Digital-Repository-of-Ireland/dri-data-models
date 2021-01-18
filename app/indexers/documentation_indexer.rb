 # frozen_string_literal: true
class DocumentationIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless resource.respond_to?(:documentation_for) && !resource.documentation_for.nil?

    { 'isDescriptionOf_ssim' => [resource.documentation_for.alternate_id] }
  end
end
