# DRI namespace
module DRI
  # Implementation of DRI::LinkedData digital objects extending from AF Base
  # for Logainm places
  class LinkedData < DRI::DigitalObject
    has_one :descMetadata, class_name: 'DRI::Metadata::QualifiedDublinCore', as: :describable, autosave: true

    delegate :creator, to: :descMetadata
    delegate :identifier, to: :descMetadata
    delegate :source, to: :descMetadata
    delegate :contributor, to: :descMetadata
    delegate :title, to: :descMetadata
    #delegate :tag, to: :descMetadata
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
      updated_props = properties.clone

      # When updating from DRI form
      # replace type attribute key with resource_type
      updated_props[:resource_type] = updated_props.delete :type

      super(updated_props)
    end

    def declared_attached_files
      { descMetadata: descMetadata, properties: properties }
    end

    # Type attribute getter
    #
    # @return [Array<String>] the array of metadata type values
    def type
      descMetadata.resource_type
    end

    # Type attribute setter
    # @param [Array<String>] type the array of metadata type values to set
    def type=(type)
      descMetadata.resource_type = type
    end

    # Retrieve an existing Fedora DRI::LinkedData object;
    # creates a new one if object not found for a given PID
    #
    # @param [String] pid the object's PID
    # @return [DRI::LinkedData] the retrieved Fedora object; new object if not found
    def self.find_or_create(pid)
      DRI::Identifier.retrieve_object!(pid)
    rescue ActiveRecord::RecordNotFound
      DRI::LinkedData.create(noid: pid)
    end

    def descMetadata
      super || build_descMetadata
    end

  end
end # Module DRI
