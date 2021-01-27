# frozen_string_literal: true
class RightsIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless resource.wrapped_object.respond_to?(:rights) && resource.wrapped_object.rights.empty?

    { 'rights_tesim' => ['No rights statement'] }
  end
end
