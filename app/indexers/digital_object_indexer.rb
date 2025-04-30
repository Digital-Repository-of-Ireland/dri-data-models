# frozen_string_literal: true
class DigitalObjectIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} if resource.wrapped_object.is_a?(::DRI::GenericFile)

    solr_doc = create_solr_document
    solr_doc.merge!(collection_file_types) if resource.wrapped_object.collection?

    solr_doc
  end

  def collection_file_types
    file_type = ['collection']
    file_type_display = if ead_level?
                          [resource.wrapped_object.ead_level.strip.capitalize]
                        else
                          ['Collection']
                        end

    {
      'file_type_tesim' => file_type,
      'file_type_sim' => file_type,
      'file_type_display_tesim' => file_type_display,
      'file_type_display_sim' => file_type_display
    }
  end

  def create_solr_document
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
      'thumbnail_ss' => resource.wrapped_object.thumbnail,
      'licence_sim' => resource.wrapped_object.licence,
      'licence_tesim' => resource.wrapped_object.licence,
      'copyright_sim' => resource.wrapped_object.copyright,
      'copyright_tesim' => resource.wrapped_object.copyright,
      'dataset_ss' => resource.wrapped_object.dataset
    }
  end

  def ead_level?
    resource.wrapped_object.respond_to?(:ead_level) && !resource.wrapped_object.root_collection? && resource.wrapped_object.ead_level.present?
  end
end
