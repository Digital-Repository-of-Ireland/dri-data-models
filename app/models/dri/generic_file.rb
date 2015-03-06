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
  include Sufia::GenericFile::VirusCheck
  include Sufia::GenericFile::FullTextIndexing

  belongs_to :batch, :class_name => "DRI::Batch", property: :is_part_of
  # Declare a 'dri_properties' DS, of the following type
  has_metadata :name => "dri_properties", :type => DRI::Metadata::FileProperties

  # Declare the attributes of 'dri_properties' DS - 'checksum_md5...' - and that the DS is non-repeatable
  has_attributes :checksum_md5, datastream: :dri_properties, multiple: false
  has_attributes :checksum_sha256, datastream: :dri_properties, multiple: false
  has_attributes :checksum_rmd160, datastream: :dri_properties, multiple: false

  # DRI is not storing files in Fedora (which would be too slow to be of practical use),
  # instead a datastream will link to a URL in the DRI storage system.
  def update_file_reference(dsid, opts)
    options = {}
    if opts.has_key?(:mimeType)
      options[:mimeType] = opts[:mimeType]
    end

    add_file(opts[:url], dsid, options)
   
    true
  end

  def milliseconds
    characterization.milliseconds.blank? ? characterization.video_milliseconds : characterization.milliseconds
  end

  # Unstemmed, searchable, stored
  def noid_indexer
    @noid_indexer ||= Solrizer::Descriptor.new(:text, :indexed, :stored)
  end 

  def indexer
    DRI::GenericFileIndexer
  end

end

class GenericFileIndexer < ActiveFedora::IndexingService

  def generate_solr_document
    solr_doc[SolrQueryBuilder.solr_name('noid', object.noid_indexer)] = noid

    solr_doc.merge!(solr_name('file_size', :stored_sortable, type: :integer) => [object.file_size[0]]) unless object.file_size.empty?
    solr_doc.merge!(solr_name('width', :stored_sortable, type: :integer) => [object.width[0]]) unless object.width.empty?
    solr_doc.merge!(solr_name('height', :stored_sortable, type: :integer) => [object.height[0]]) unless object.height.empty?
    if (!width.empty? && !height.empty?)
      solr_doc.merge!(solr_name('area', :stored_sortable, type: :integer) => [object.width[0].to_i*object.height[0].to_i])
    end

    solr_doc.merge!(solr_name('duration', :stored_sortable, type: :integer) => [object.milliseconds[0]]) unless object.milliseconds.empty?
    solr_doc.merge!(solr_name('channels', :stored_sortable, type: :integer) => [object.channels[0]]) unless object.channels.empty?
    solr_doc.merge!(solr_name('sample_rate', :stored_sortable, type: :integer) => [object.sample_rate[0]]) unless object.sample_rate.empty?
   
    file_type = []
    file_type.push "audio" if object.audio?
    file_type.push "video" if object.video?
    file_type.push "image" if object.image?
    file_type.push "text" if object.text?
    solr_doc.merge!(solr_name('file_type', :stored_searchable) => file_type)
    solr_doc.merge!(solr_name('file_type', :facetable) => file_type)
  end
end

end
