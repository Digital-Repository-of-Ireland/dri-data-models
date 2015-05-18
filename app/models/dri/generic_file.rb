module DRI
class GenericFile < ActiveFedora::Base
  include Sufia::GenericFile
  include Sufia::ModelMethods
  include Sufia::Noid
  include Sufia::GenericFile::MimeTypes
  include Sufia::GenericFile::Export
  include Sufia::GenericFile::Characterization
  include Sufia::GenericFile::Permissions
  include Sufia::GenericFile::Derivatives
  include Sufia::GenericFile::Trophies
  include Sufia::GenericFile::Metadata
  include Sufia::GenericFile::Versions
  include Sufia::GenericFile::Content
  include Sufia::GenericFile::VirusCheck
  include Sufia::GenericFile::FullTextIndexing

  belongs_to :batch, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: "DRI::Batch"

  belongs_to :documentation, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isConstituentOf, class_name: "DRI::Documentation"

  # Declare a 'dri_properties' DS, of the following type
  contains "dri_properties", class_name: "DRI::Metadata::FileProperties"

  # Declare the attributes of 'dri_properties' DS - 'checksum_md5...' - and that the DS is non-repeatable
  has_attributes :checksum_md5, datastream: :dri_properties, multiple: false
  has_attributes :checksum_sha256, datastream: :dri_properties, multiple: false
  has_attributes :checksum_rmd160, datastream: :dri_properties, multiple: false
  has_attributes :preservation_only, datastream: :dri_properties, multiple: false

  # DRI is not storing files in Fedora (which would be too slow to be of practical use),
  # instead a datastream will link to a URL in the DRI storage system.
  def update_file_reference(dsid, opts)
    options = {}
    if opts.has_key?(:mimeType)
      options[:mime_type] = opts[:mimeType]
    end

    options[:path] = dsid
    self.attach_file(opts[:url], dsid, options)
   
    true
  end

  def milliseconds
    characterization.milliseconds.blank? ? characterization.video_milliseconds : characterization.milliseconds
  end
  
  def to_solr(solr_doc={}, opts={})
    solr_doc = super(solr_doc)
    
    solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('file_size', :stored_sortable, type: :integer) => [file_size[0]]) unless file_size.empty?
    solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('width', :stored_sortable, type: :integer) => [width[0]]) unless width.empty?
    solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('height', :stored_sortable, type: :integer) => [height[0]]) unless height.empty?
    if (!width.empty? && !height.empty?)
      solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('area', :stored_sortable, type: :integer) => [width[0].to_i*height[0].to_i])
    end

    solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('duration', :stored_sortable, type: :integer) => [milliseconds[0]]) unless milliseconds.empty?
    solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('channels', :stored_sortable, type: :integer) => [channels[0]]) unless channels.empty?
    solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('sample_rate', :stored_sortable, type: :integer) => [sample_rate[0]]) unless sample_rate.empty?
   
    file_type = []
    file_type.push "audio" if audio?
    file_type.push "video" if video?
    file_type.push "image" if image?
    file_type.push "text" if text?
    solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('file_type', :stored_searchable) => file_type)
    solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('file_type', :facetable) => file_type)

    solr_doc
  end

end
end
