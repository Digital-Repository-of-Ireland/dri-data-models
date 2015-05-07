module DRI
  class LinkedData < ActiveFedora::Base
    include Sufia::Noid

    has_metadata :name => "descMetadata", :type => DRI::Metadata::LinkedData

    has_attributes :creator, :identifier, :source,
                   :contributor, :title, :tag, :description, 
                   :publisher, :date_created, :subject,
                   :resource_type, :identifier, :language, datastream: :descMetadata, multiple: true

    has_attributes :spatial, datastream: :descMetadata, multiple: true

    def attributes=(properties)
      super(properties)
    end

    def self.find_or_create(pid)
      begin
        DRI::LinkedData.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
        DRI::LinkedData.create({pid: pid})
      end
    end

    # Unstemmed, searchable, stored
    def noid_indexer
      @noid_indexer ||= Solrizer::Descriptor.new(:text, :indexed, :stored)
    end

    def to_solr(solr_doc={}, opts={})
      super(solr_doc, opts).tap do |solr_doc|
        solr_doc[Solrizer.solr_name('noid', noid_indexer)] = noid
      end
    end
      
  end 
end # Module DRI
