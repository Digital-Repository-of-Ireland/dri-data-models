class Batch < ActiveFedora::Base
  include ActiveFedora::Auditable
  include Sufia::ModelMethods
  include Sufia::Noid
  include Sufia::GenericFile::Export
  include DRI::ModelSupport::Properties
  include DRI::ModelSupport::Permissions
  include DRI::ModelSupport::InterchangeableMetadata
  include DRI::ModelSupport::Collections
      
  has_many :generic_files, :property => :is_part_of

  def self.find_or_create(pid)
    begin
      Batch.find(pid)
    rescue ActiveFedora::ObjectNotFoundError
      Batch.create({pid: pid})
    end
  end

  def to_solr(solr_doc={}, opts={})
    super(solr_doc, opts)

    solr_doc[Solrizer.solr_name('noid', Sufia::GenericFile.noid_indexer)] = noid

    solr_doc.merge!collections_to_solr
    solr_doc.merge!object_types_to_solr

    return solr_doc
  end
end
