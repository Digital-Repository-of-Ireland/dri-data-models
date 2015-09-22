module DRI
  class LinkedData < ActiveFedora::Base
    include Sufia::Noid

    contains 'descMetadata', class_name: 'DRI::Metadata::LinkedData'

    property :creator, delegate_to: 'descMetadata', multiple: true
    property :identifier, delegate_to: 'descMetadata', multiple: true
    property :source, delegate_to: 'descMetadata', multiple: true
    property :contributor, delegate_to: 'descMetadata', multiple: true
    property :title, delegate_to: 'descMetadata', multiple: true
    property :tag, delegate_to: 'descMetadata', multiple: true
    property :description, delegate_to: 'descMetadata', multiple: true
    property :publisher, delegate_to: 'descMetadata', multiple: true
    property :date_created, delegate_to: 'descMetadata', multiple: true
    property :subject, delegate_to: 'descMetadata', multiple: true
    property :resource_type, delegate_to: 'descMetadata', multiple: true
    property :identifier, delegate_to: 'descMetadata', multiple: true
    property :language, delegate_to: 'descMetadata', multiple: true
    property :spatial, delegate_to: 'descMetadata', multiple: true

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
