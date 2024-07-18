# frozen_string_literal: true
# DRI namespace
module DRI
  # Implementation of DRI EAD digital objects
  class EadCollection < DRI::DigitalObject
    include DRI::EncodedArchivalDescription

    around_save :synchronize_if_changed # trigger EAD children creation

    has_one :descMetadata, class_name: 'DRI::Metadata::EncodedArchivalDescription', as: :describable, autosave: true

    delegate :collection?, to: :descMetadata

    def descMetadata
      super || build_descMetadata
    end

    def fullMetadata
      super || build_fullMetadata
    end
  end
end
