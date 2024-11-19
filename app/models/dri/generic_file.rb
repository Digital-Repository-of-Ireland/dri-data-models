# DRI namespace
module DRI
  # Implementation of DRI generic files (digital assets) extending from AR Base
  # and associated to Digital Objects extending from DRI::DigitalObject
  # DRI::EncodedArchivalDescription, DRI::QualifiedDublinCore, DRI::Mods, DRI::Marc
  # DRI::Documentation
  class GenericFile < ApplicationRecord
    include DRI::Indexing

    include DRI::WithDepositor

    include DRI::Noid
    include DRI::Export
    include DRI::Asset::MimeTypes
    include DRI::Asset::Characterization
    include DRI::Asset::Permissions::Readable
    include DRI::Asset::Derivatives
    include DRI::Asset::Versions

    include DRI::ModelSupport::LocalFile

    has_one :alternate_identifier, class_name: 'DRI::Identifier', as: :identifiable, dependent: :nullify

    include DRI::Derivatives::ExtractMetadata

    # one-to-one association to associate DRI::DigitalObject
    belongs_to :digital_object, class_name: 'DRI::DigitalObject', polymorphic: true, autosave: true

    serialize :title, coder: YAML
    serialize :creator, coder: YAML

    delegate :alternate_id, :alternate_id=, to: :alternate_identifier

    def self.find_by_alternate_id(pid)
      joins(:alternate_identifier).where(dri_identifiers: { alternate_id: pid }).take
    end

    def self.find_by_alternate_id!(pid)
      object = find_by_alternate_id(pid)
      raise(ActiveRecord::RecordNotFound, "Couldn't find DRI::GenericFile with 'alternate_id'=#{pid}") unless object

      object
    end

    def declared_attached_files
      { 'characterization' => characterization }
    end

    def attached_files
      declared_attached_files
    end

    def create_date
      return nil unless created_at
      DateTime.parse(created_at.to_s).utc.to_datetime
    end

    def modified_date
      return nil unless updated_at
      DateTime.parse(updated_at.to_s).utc.to_datetime
    end

    def alternate_identifier
      super || build_alternate_identifier
    end

    # Asserts the model class
    def model_types
      [self.class.to_s]
    end

    # Return number of milliseconds for the duration of this asset file
    # @return [Integer] number of milliseconds
    def milliseconds
      characterization.milliseconds.presence || characterization.video_milliseconds
    end

    def related_files
      return [] unless digital_object
      digital_object.generic_files.reject { |sibling| sibling.id == id }
    end

    # Is this file in the middle of being processed by an object?
    def processing?
      try(:digital_object).try(:status) == ['processing'.freeze]
    end
  end
end
