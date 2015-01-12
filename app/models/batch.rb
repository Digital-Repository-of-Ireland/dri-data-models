class Batch < ActiveFedora::Base
  include ActiveFedora::Auditable
  include Sufia::ModelMethods
  include Sufia::Noid
  include Sufia::GenericFile::Export
  include Sufia::GenericFile::ReloadOnSave
  include DRI::ModelSupport::Properties
  include DRI::ModelSupport::Permissions
  include DRI::ModelSupport::InterchangeableMetadata
  include DRI::ModelSupport::Files
  include DRI::ModelSupport::Collections

  has_many :generic_files, :property => :is_part_of

  # Declare a 'extracted' DS, of the following type
  has_metadata :name => "extracted", :type => DRI::Metadata::Extracted

  # Declare the attributes of 'extracted' DS - 'full_text' - and that the DS is repeatable
  has_attributes :full_text, datastream: :extracted, multiple: true

  # Creates or finds (if pid provided) a Batch object
  # @param pid [String] the pid of an existing Batch object
  def self.find_or_create(pid)
    begin
      Batch.find(pid)
    rescue ActiveFedora::ObjectNotFoundError
      Batch.create({pid: pid})
    end
  end

  # Initialises the Solr index field (and its type) for this object
  def noid_indexer
    # Unstemmed, searchable, stored
    @noid_indexer ||= Solrizer::Descriptor.new(:text, :indexed, :stored)
  end

  # Performs the indexing of this object into Solr
  # @param solr_doc []
  def to_solr(solr_doc={}, opts={})
    solr_doc = super(solr_doc, opts)

    solr_doc[Solrizer.solr_name('noid', noid_indexer)] = noid

    solr_doc.merge!collections_to_solr
    solr_doc.merge!object_types_to_solr
    solr_doc.merge!file_metadata_to_solr

    # TODO - Add full_text, unimplemented
    solr_doc.merge!('all_text_timv' => full_text)

    return solr_doc
  end
end
