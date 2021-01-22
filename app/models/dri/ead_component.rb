# DRI namespace
module DRI
  # Implementation of DRI Marc digital objects
  class EadComponent < DRI::DigitalObject
    include DRI::EncodedArchivalDescription

    around_save :synchronize_if_changed # trigger EAD children creation

    has_one :descMetadata, class_name: 'DRI::Metadata::EncodedArchivalDescriptionComponent', as: :describable, autosave: true

    def descMetadata
      super || build_descMetadata
    end

    def fullMetadata
      super || build_fullMetadata
    end

    def collection?
      descMetadata.collection?
    end

    def method_missing(method, *args)
      descMetadata.send(method, *args) if descMetadata.respond_to?(method)
    end
  end
end
