# DRI namespace
module DRI
  # Implementation of DRI::LinkedData digital objects extending from AF Base
  # for Logainm places
  class LinkedData < DRI::DigitalObject
    has_one :descMetadata, class_name: 'DRI::Metadata::LinkedData'

    delegate :creator, to: :descMetadata
    delegate :identifier, to: :descMetadata
    delegate :source, to: :descMetadata
    delegate :contributor, to: :descMetadata
    delegate :title, to: :descMetadata
    delegate :tag, to: :descMetadata
    delegate :description, to: :descMetadata
    delegate :publisher, to: :descMetadata
    delegate :date_created, to: :descMetadata
    delegate :subject, to: :descMetadata
    delegate :resource_type, to: :descMetadata
    delegate :identifier, to: :descMetadata
    delegate :language, to: :descMetadata
    delegate :spatial, to: :descMetadata

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
    rescue ActiveRecord::RecordNotFound
      DRI::LinkedData.create(id: pid)
    end

    def descMetadata
      super || build_descMetadata
    end

    # Override from AF method
    def to_solr(solr_doc = {}, opts = {})
      super(solr_doc, opts)
    end
  end 
end # Module DRI
