class GenericFile < ActiveFedora::Base
  include Sufia::GenericFile

  #after_initialize :redirect_content

  has_metadata :name => "dri_properties", :type => DRI::Metadata::FileProperties

  has_attributes :checksum_md5, datastream: :dri_properties, multiple: false
  has_attributes :checksum_sha256, datastream: :dri_properties, multiple: false
  has_attributes :checksum_rmd160, datastream: :dri_properties, multiple: false

  # DRI is not storing files in Fedora (which would be too slow to be of practical use),
  # instead a datastream will link to a URL in the DRI storage system.
  def update_file_reference(dsid, opts)
    if datastreams.has_key?(dsid) 
      (send dsid).dsLocation = opts[:url]
      if opts.has_key?(:mimeType)
        (send dsid).mimeType = opts[:mimeType]
      end
      (send dsid).controlGroup = 'R'
      true
    else
      false
    end
  end

  def milliseconds
    characterization.milliseconds.blank? ? characterization.video_milliseconds : characterization.milliseconds
  end

  def to_solr(solr_doc={}, opts={})
    super(solr_doc, opts)
    solr_doc[Solrizer.solr_name('noid', Sufia::GenericFile.noid_indexer)] = noid

    solr_doc.merge!(solr_name('file_size', :stored_sortable, type: :integer) => file_size)
    solr_doc.merge!(solr_name('width', :stored_sortable, type: :integer) => width)
    solr_doc.merge!(solr_name('height', :stored_sortable, type: :integer) => height)
    if (!width.empty? && !height.empty?)
      solr_doc.merge!(solr_name('image_area', :stored_sortable, type: :integer) => [width[0].to_i*height[0].to_i])
    end

    solr_doc.merge!(solr_name('duration', :stored_sortable, type: :integer) => milliseconds)
    solr_doc.merge!(solr_name('channels', :stored_sortable, type: :integer) => channels)
    solr_doc.merge!(solr_name('sample_rate', :stored_sortable, type: :integer) => sample_rate)
    #solr_doc.merge!(solr_name('bit_depth', :stored_sortable, type: :integer) => bit_depth)

    file_type = []
    file_type.push "audio" if audio?
    file_type.push "video" if video?
    file_type.push "image" if image?
    file_type.push "text" if text?
    solr_doc.merge!(solr_name('file_type', :stored_searchable) => file_type)
    solr_doc.merge!(solr_name('file_type', :facetable) => file_type)

    return solr_doc
  end

end


