# frozen_string_literal: true
class FileMetadataIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    solr_doc = {}
    return solr_doc unless resource.respond_to?(:generic_file)

    if resource.collection?
      file_type =  ['collection']
      file_type_display = ['Collection']

      solr_doc.merge!('file_type_tesim' => file_type)
      solr_doc.merge!('file_type_sim' => file_type)

      solr_doc.merge!('file_type_display_tesim' => file_type_display)
      solr_doc.merge!('file_type_display_sim' => file_type_display)
    end

    solr_doc = index_file_metadata(solr_doc) if resource.generic_files.count > 0

    unless solr_doc.key?('file_type_tesim')
      solr_doc = file_type_from_metadata(solr_doc)
    end

    solr_doc
  end

  def index_file_metadata(no_of_files, solr_doc = {})
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

    resource.generic_files.each do |generic_file|
      gf = generic_file.to_solr
      file_count += 1
      if !resource.collection? && gf.key?('file_type_tesim')
        file_type |= [gf['file_type_tesim'][0]]
        file_type_display |= [gf['file_type_tesim'][0].capitalize]
      end
      if gf.key?('width_isi')
        width |= [gf['width_isi']]
      end
      if gf.key?('height_isi')
        height |= [gf['height_isi']]
      end
      if gf.key?('area_isi')
        area |= [gf['area_ssi']]
      end
      if gf.key?('channels_isi')
        channels |= [gf['channels_isi']]
      end
      if gf.key?('bit_depth_isi')
        bit_depth |= [gf['bit_depth_isi']]
      end
      if gf.key?('sample_rate_isi')
        sample_rate |= [gf['sample_rate_isi']]
      end
      if gf.key?('duration_isi')
        duration_total = 0 if duration_total.nil?
        duration_total += gf['duration_isi']
        duration |= [gf['duration_isi']]
      end
      if gf.key?('file_size_isi')
        file_size_total = 0 if file_size_total.nil?
        file_size_total += gf['file_size_isi'].first
        file_size |= gf['file_size_isi']
      end
      if gf.key?('mime_type_tesim')
        mime_type |= [gf['mime_type_tesim']]
      end
      if gf.key?('file_format_tesim')
        file_format |= [gf['file_format_tesim']] unless gf['file_format_tesim'].nil?
      end
    end

    solr_doc.merge!('width_isim' => width)
    solr_doc.merge!('width_sim' => width)
    solr_doc.merge!('height_isim' => height)
    solr_doc.merge!('height_sim' => height)
    solr_doc.merge!('area_isim' => area)
    solr_doc.merge!('area_sim' => area)
    solr_doc.merge!('channels_isim' => channels)
    solr_doc.merge!('channels_sim' => channels)
    solr_doc.merge!('bit_depth_isim' => bit_depth)
    solr_doc.merge!('bit_depth_sim' => bit_depth)
     solr_doc.merge!('sample_rate_isim' => sample_rate)
    solr_doc.merge!('sample_rate_sim' => sample_rate)

    unless duration_total.nil?
      solr_doc.merge!('duration_total_isi' => [duration_total])
      solr_doc.merge!('duration_tesim' => duration)
      solr_doc.merge!('duration_sim' => duration)
    end

    unless file_size_total.nil?
      solr_doc.merge!('file_size_total_isi' => file_size_total)
      solr_doc.merge!('file_size_isim' => file_size)
      solr_doc.merge!('file_size_sim' => file_size)
    end

    unless file_type.empty?
      solr_doc.merge!('file_type_tesim' => file_type)
      solr_doc.merge!('file_type_sim' => file_type)

      solr_doc.merge!('file_type_display_tesim' => file_type_display)
      solr_doc.merge!('file_type_display_sim' => file_type_display)
    end

    solr_doc.merge!('mime_type_tesim' => mime_type)
    solr_doc.merge!('mime_type_sim' => mime_type)

    solr_doc.merge!('file_format_tesim' => file_format)
    solr_doc.merge!('file_format_sim' => file_format)

    solr_doc.merge!('file_count_isi' => [file_count])

    solr_doc
  end

  def file_type_from_metadata(solr_doc)
    # As a last resort try to determine the file type from the
    # DCMI vocabulary in the metadata.
    file_type = []
    file_type_display = []

    resource.type.each do |value|
      next unless DRI::Vocabulary.dcmi_type.include?(value.capitalize)
      file_type.push(value)
      file_type_display.push(value.capitalize)
      break
    end

    if file_type.empty?
      file_type.push 'unknown'
      file_type_display.push 'Unknown'
    end

    solr_doc.merge!('file_type_tesim' => file_type)
    solr_doc.merge!('file_type_sim' => file_type)

    solr_doc.merge!('file_type_display_tesim' => file_type_display)
    solr_doc.merge!('file_type_display_sim' => file_type_display)

    solr_doc
  end
end
