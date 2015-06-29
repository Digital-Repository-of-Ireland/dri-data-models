module DRI
  class LinkedData < ActiveFedora::Base
    include Sufia::Noid

    contains "descMetadata", class_name: "DRI::Metadata::LinkedData"

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
        DRI::LinkedData.create({id: pid})
      end
    end

    def to_solr(solr_doc={}, opts={})
      super(solr_doc, opts)
    end
      
  end 
end # Module DRI
