# frozen_string_literal: true
class FileMetadataIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless resource.wrapped_object.respond_to?(:generic_files) && resource.wrapped_object.generic_files.present?

    solr_doc = {}

    solr_doc.merge!(index_file_metadata) if resource.wrapped_object.generic_files.count.positive?
    solr_doc.merge!(file_type_from_metadata) unless solr_doc.key?('file_type_tesim')

    solr_doc
  end

  private

  def file_type_fields(file_type, file_type_display)
    {
      'file_type_tesim' => file_type,
      'file_type_sim' => file_type,
      'file_type_display_tesim' => file_type_display,
      'file_type_display_sim' => file_type_display
    }
  end

  def index_file_metadata
    file_type = []
    file_type_display = []
    file_count = 0
    width = []
    height = []
    area = []
    duration = []
    duration_total = nil
    file_size = []
    file_size_total = nil
    mime_type = []
    channels = []
    bit_depth = []
    sample_rate = []
    file_format = []

    resource.wrapped_object.generic_files.each do |generic_file|
      gf = generic_file.to_solr
      file_count += 1

      if !resource.wrapped_object.collection? && gf.key?('file_type_tesim')
        file_type |= [gf['file_type_tesim'][0]]
        file_type_display |= [gf['file_type_tesim'][0].capitalize]
      end

      width |= [gf['width_isi']] if gf.key?('width_isi')
      height |= [gf['height_isi']] if gf.key?('height_isi')
      area |= [gf['area_ssi']] if gf.key?('area_isi')
      channels |= [gf['channels_isi']] if gf.key?('channels_isi')
      bit_depth |= [gf['bit_depth_isi']] if gf.key?('bit_depth_isi')
      sample_rate |= [gf['sample_rate_isi']] if gf.key?('sample_rate_isi')
      mime_type |= gf['mime_type_tesim'] if gf.key?('mime_type_tesim')

      if gf.key?('duration_isi')
        duration_total = 0 if duration_total.nil?
        duration_total += gf['duration_isi'].to_i
        duration |= [gf['duration_isi'].to_i]
      end
      if gf.key?('file_size_isi')
        file_size_total = 0 if file_size_total.nil?
        file_size_total += gf['file_size_isi'].to_i
        file_size |= [gf['file_size_isi'].to_i]
      end

      if gf.key?('file_format_tesim')
        file_format |= [gf['file_format_tesim']] unless gf['file_format_tesim'].nil?
      end
    end

    file_metadata = {
      'width_isim' => width,
      'width_sim' => width,
      'height_isim' => height,
      'height_sim' => height,
      'area_isim' => area,
      'area_sim' => area,
      'channels_isim' => channels,
      'channels_sim' => channels,
      'bit_depth_isim' => bit_depth,
      'bit_depth_sim' => bit_depth,
      'sample_rate_isim' => sample_rate,
      'sample_rate_sim' => sample_rate
    }

    unless duration_total.nil?
      file_metadata.merge!(
        {
          'duration_total_isi' => [duration_total],
          'duration_tesim' => duration,
          'duration_sim' => duration
        }
      )
    end

    unless file_size_total.nil?
      file_metadata.merge!(
        {
          'file_size_total_isi' => file_size_total,
          'file_size_isim' => file_size,
          'file_size_sim' => file_size
        }
      )
    end


    file_metadata.merge!(file_type_fields(file_type, file_type_display)) unless file_type.empty?

    file_metadata.merge(
      {
        'mime_type_tesim' => mime_type,
        'mime_type_sim' => mime_type,
        'file_format_tesim' => file_format,
        'file_format_sim' => file_format,
        'file_count_isi' => file_count
      }
    )
  end

  def file_type_from_metadata
    # As a last resort try to determine the file type from the
    # DCMI vocabulary in the metadata.
    file_type = []
    file_type_display = []

    resource.wrapped_object.type.each do |value|
      next unless DRI::Vocabulary.dcmi_type.include?(value.capitalize)
      file_type.push(value)
      file_type_display.push(value.capitalize)
      break
    end

    if file_type.empty?
      file_type.push 'unknown'
      file_type_display.push 'Unknown'
    end

    file_type_fields(file_type, file_type_display)
  end
end
