# frozen_string_literal: true
class DigitalObjectIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} if resource.wrapped_object.is_a?(::DRI::GenericFile)

    {
      'status_ssi' => resource.wrapped_object.status,
      'depositor_sim' => resource.wrapped_object.depositor,
      'depositor_ss' => resource.wrapped_object.depositor,
      'published_at_dttsi' => resource.wrapped_object.published_at,
      'metadata_checksum_ssi' => resource.wrapped_object.metadata_checksum,
      'depositing_institute_ssi' => resource.wrapped_object.depositing_institute,
      'institute_tesim' => resource.wrapped_object.institute,
      'institute_sim' => resource.wrapped_object.institute,
      'doi_ss' => resource.wrapped_object.doi,
      'cover_image_ss' => resource.wrapped_object.cover_image,
      'licence_sim' => resource.wrapped_object.licence,
      'licence_tesim' => resource.wrapped_object.licence
    }
  end
end
