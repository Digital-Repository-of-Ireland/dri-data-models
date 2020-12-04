# frozen_string_literal: true
class GenericFileIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless resource.is_a?(::DRI::GenericFile)
    solr_doc = {}

    if resource.digital_object
      solr_doc['isPartOf_ssim'] = [resource.digital_object.noid]
    end

    solr_doc.merge!(
        {
            'preservation_only_tesim' => resource.preservation_only,
            'file_size_isi' => [resource.file_size]
        }
    )
    solr_doc['width_isi'] = [resource.width[0].to_i] unless resource.width.empty?
    solr_doc['height_isi'] = [resource.height[0].to_i] unless resource.height.empty?

    unless resource.width.empty? || resource.height.empty?
      solr_doc['area_isi'] = [resource.width[0].to_i * resource.height[0].to_i]
    end

    solr_doc['duration_isi'] = [resource.milliseconds[0]] unless resource.milliseconds.empty?
    solr_doc['channels_isi'] = [resource.channels[0]] unless resource.channels.empty?
    solr_doc['sample_rate_isi'] = [resource.sample_rate[0].to_i] unless resource.sample_rate.empty?
    solr_doc['mime_type_tesim'] = resource.mime_type unless resource.mime_type.empty?

    file_type = []
    file_type.push('audio') if resource.audio?
    file_type.push('video') if resource.video?
    file_type.push('image') if resource.image?
    file_type.push('text') if resource.text?
    file_type.push('3d') if resource.threeD?

    unless file_type.empty?
      solr_doc.merge!(
        {
            'file_type_tesim' => file_type,
            'file_type_sim' => file_type
        }
      )
    end

    solr_doc['label_tesim'] = resource.label
    solr_doc['file_format_tesim'] = resource.file_format
    solr_doc['file_format_sim'] = resource.file_format
    #solr_doc['all_text_timv'] = full_text.content

    solr_doc
  end
end
