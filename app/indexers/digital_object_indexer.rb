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
      'published_at_dttsi' => resource.published_at,
      'metadata_checksum_ssi' => resource.metadata_checksum,
      'depositing_institute_ssi' => resource.depositing_institute,
      'institute_tesim' => resource.institute,
      'institute_sim' => resource.institute,
      'doi_ss' => resource.doi,
      'cover_image_ss' => resource.cover_image
    }
  end
end
