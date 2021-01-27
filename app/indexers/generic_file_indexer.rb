# frozen_string_literal: true
class GenericFileIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless resource.wrapped_object.is_a?(::DRI::GenericFile)
    solr_doc = {}
    if resource.wrapped_object.digital_object
      solr_doc['isPartOf_ssim'] = [resource.wrapped_object.digital_object.alternate_id]
    end

    solr_doc['preservation_only_ssi'] = resource.wrapped_object.preservation_only
    solr_doc['file_size_isi'] = [resource.wrapped_object.file_size]
    solr_doc['width_isi'] = [resource.wrapped_object.width[0].to_i] unless resource.wrapped_object.width.empty?
    solr_doc['height_isi'] = [resource.wrapped_object.height[0].to_i] unless resource.wrapped_object.height.empty?

    unless resource.wrapped_object.width.empty? || resource.wrapped_object.height.empty?
      solr_doc['area_isi'] = [resource.wrapped_object.width[0].to_i * resource.wrapped_object.height[0].to_i]
    end

    solr_doc['duration_isi'] = [resource.wrapped_object.milliseconds[0]] unless resource.wrapped_object.milliseconds.empty?
    solr_doc['channels_isi'] = [resource.wrapped_object.channels[0]] unless resource.wrapped_object.channels.empty?
    solr_doc['sample_rate_isi'] = [resource.wrapped_object.sample_rate[0].to_i] unless resource.wrapped_object.sample_rate.empty?
    solr_doc['mime_type_tesim'] = resource.wrapped_object.mime_type unless resource.wrapped_object.mime_type.empty?

    file_type = []
    file_type.push('audio') if resource.wrapped_object.audio?
    file_type.push('video') if resource.wrapped_object.video?
    file_type.push('image') if resource.wrapped_object.image?
    file_type.push('text') if resource.wrapped_object.text?
    file_type.push('3d') if resource.wrapped_object.threeD?

    if file_type.present?
      solr_doc['file_type_tesim'] = file_type
      solr_doc['file_type_sim'] = file_type
    end

    solr_doc['label_tesim'] = resource.wrapped_object.label
    solr_doc['file_format_tesim'] = resource.wrapped_object.file_format
    solr_doc['file_format_sim'] = resource.wrapped_object.file_format
    # solr_doc['all_text_timv'] = full_text.content

    solr_doc
  end
end
