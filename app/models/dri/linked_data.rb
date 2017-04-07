# DRI namespace
module DRI
  # Implementation of DRI::LinkedData digital objects extending from AF Base
  # for Logainm places
  class LinkedData < ActiveFedora::Base
    include DRI::Noid

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

    # AF Override
    # Set the object's attributes
    # @param [Hash] properties the hash with the object's properties
    def attributes=(properties)
      super(properties)
    end

    # Retrieve an existing Fedora DRI::LinkedData object;
    # creates a new one if object not found for a given PID
    #
    # @param [String] pid the object's PID
    # @return [DRI::LinkedData] the retrieved Fedora object; new object if not found
    def self.find_or_create(pid)
      DRI::LinkedData.find(pid)
    rescue ActiveFedora::ObjectNotFoundError
      DRI::LinkedData.create(id: pid)
    end

    # Override from AF method
    def to_solr(solr_doc = {}, opts = {})
      super(solr_doc, opts)
    end
  end 
end # Module DRI
