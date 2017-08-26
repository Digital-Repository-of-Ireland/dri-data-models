# DRI namespace
module DRI
  # Implementation of DRI Marc digital objects extending from DRI::Base
  class EadCollection < DRI::DigitalObject
    include DRI::EncodedArchivalDescription

    around_save :synchronize_if_changed # trigger EAD children creation

    has_one :descMetadata, class_name: 'DRI::Metadata::EncodedArchivalDescription', as: :describable, autosave: true

    def descMetadata
      super || build_descMetadata
    end

    def fullMetadata
      super || build_fullMetadata
    end

    def collection?
      descMetadata.collection?
    end

    # Retrieve an existing Fedora DRI::EncodedArchivalDescription object;
    # creates a new one if object not found for a given PID
    #
    # @param [String] pid the object's PID
    # @return [DRI::EncodedArchivalDescription] the retrieved Fedora object; new object if not found
    def self.find_or_create(pid)
      DRI::EadCollection.find_by!(noid: pid)
    rescue ActiveRecord::RecordNotFound
      DRI::EadCollection.create(noid: pid)
    end

    def method_missing(method, *args)
      descMetadata.send(method, *args) if descMetadata.respond_to?(method)
    end
  end
end