# frozen_string_literal: true
class DigitalObjectIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} if resource.is_a?(::DRI::GenericFile)

    {
      'status_ssi' => resource.status,
      'depositor_sim' => resource.depositor,
      'depositor_ss' => resource.depositor,
      'published_at_dttsi' => resource.published_at
    }
  end
end
