class GenericFile < ActiveFedora::Base
  include Sufia::GenericFile

  #after_initialize :redirect_content

  has_metadata :name => "properties", :type => DRI::Metadata::FileProperties

  delegate :checksum_md5, :to=>"properties", :unique=>"true"
  delegate :checksum_sha256, :to=>"properties", :unique=>"true"
  delegate :checksum_rmd160, :to=>"properties", :unique=>"true"

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

  #def redirect_content
  #  if content.controlGroup == 'M'
  #    content.controlGroup = 'R'
  #  end
  #end

  def to_solr(solr_doc={}, opts={})
    super(solr_doc, opts)
    solr_doc[Solrizer.solr_name('noid', Sufia::GenericFile.noid_indexer)] = noid
    return solr_doc
  end
end