# Namespace for classes and modules that handle DRI digital objects
# extending from active-fedora
#
module DRI
  # Generic DRI digital object
  # Digital objects in DRI that handle the supported metadata standards
  # inherit from this class
  #
  class DigitalObject < ApplicationRecord
    include DRI::Indexing
    include DRI::Noid
    include DRI::Export
    include DRI::Permissions
    include DRI::WithDepositor

    include DRI::ModelSupport::Permissions
    include DRI::ModelSupport::Common
    include DRI::ModelSupport::Properties
    include DRI::ModelSupport::Files
    include DRI::ModelSupport::Collections

    self.inheritance_column = 'digital_object_type'

    after_destroy :delete_files
    after_destroy :delete_objects

    # Declare a 'extracted' DS, of the following type
    # Unused for NOW
    #has_many 'extracted', class_name: 'DRI::Metadata::Extracted'

    # Declare the attributes of 'extracted' DS - 'full_text' - and that the DS is repeatable
    # Unused for NOW
    #delegate :full_text, to: 'extracted'

    # Creates a digital object depending on the metadata standard
    #
    # @param standard [Symbol] the metadata standard for the new object
    # @option standard [Symbol] :marc
    # @option standard [Symbol] :mods
    # @option standard [Symbol] :ead_collection
    # @option standard [Symbol] :ead_component
    # @option standard [Symbol] :qdc
    # @param args [Hash] hash of additional options
    # @return the new digital object
    def self.with_standard(standard, args = {})
      case standard
      when :marc
        Marc.new(args)
      when :qdc
        QualifiedDublinCore.new(args)
      when :ead_collection
       EadCollection.new(args)
      when :ead_component
        EadComponent.new(args)
      when :mods
        Mods.new(args)
      when :documentation
        Documentation.new(args)
      else
        QualifiedDublinCore.new(args)
      end
    end

    def self.find_by_noid(pid)
      joins(:alternate_identifier).where(dri_identifiers: { alternate_id: pid }).take
    end

    def self.find_by_noid!(pid)
      object = find_by_noid(pid)
      raise ActiveRecord::RecordNotFound.new("Couldn't find DRI::DigitalObject with 'noid'=#{pid}") unless object

      object
    end

    # Retrieves a digital object from fedora given its pid; creates
    # a new object if object not found
    #
    # @param pid [String] the pid of the object to retrieve
    # @return [DRI::Base] the digital object.
    def self.find_or_create(pid)
      DRI::DigitalObject.find_by_noid!(pid)
    rescue ActiveRecord::RecordNotFound
      DRI::DigitalObject.create(noid: pid)
    end

    def [](key)
        super
    rescue ActiveModel::MissingAttributeError
      self.declared_attached_files.each do |_name, file|
        if file.class.terminology.has_term?(key)
          return file.send(key.to_s)
        end
      end

      raise ActiveModel::MissingAttributeError, "Unknown attribute #{key}"
    end

    def []=(key, value)
      super
    rescue ActiveModel::MissingAttributeError
      self.declared_attached_files.each do |_name, file|
        if file.class.terminology.has_term?(key)
          file.send(key.to_s + "=", value)
          return
        end
      end

      raise ActiveModel::MissingAttributeError, "Unknown attribute #{key}"
    end

    # @note Use this in preference over setting xml directly in the OmDatastreams
    # Updates the xml metadata of this object
    #
    # @param xml_text [String, File] xml string metadata content or a file
    # @param _ingest [Boolean] flag to determine if this is part of an ingest
    # @return [boolean] true if success; false otherwise
    def update_metadata(xml_text, _ingest = true)
      xml_text = xml_text.read if xml_text.is_a?(File)
      descMetadata.ng_xml = xml_text

      true
    end

    # Asserts the model class
    def has_model
      [self.class.to_s, self.class.superclass.to_s]
    end

    # Determine whether the metadata describes a collection
    # @return [Boolean] true if metadata specified this is a collection; false otherwise
    def collection?
      descMetadata.resource_type.include? 'Collection' if descMetadata.resource_type.present?
    end

    def create_date
      return nil unless created_at
      DateTime.parse(created_at.to_s).utc.to_datetime
    end

    def depositing_institute
      properties.depositing_institute.first if properties.depositing_institute.present?
    end

    def object_version
      self[:object_version] || 1
    end

    def increment_version
      return 1 if object_version.nil?

      self.object_version = self.object_version.next
    end

    def metadata_checksum=(checksum)
      properties.metadata_md5 = checksum
      super(checksum)
    end

    def modified_date
      m_dates = [descMetadata, properties].map do |file|
                  file.updated_at.to_i
                end

      return Time.at(m_dates.sort.last).utc.to_datetime
    end

    def noid
      alternate_identifier.alternate_id
    end

    def noid=(identifier)
      alternate_identifier.alternate_id=identifier
    end

    def alternate_identifier
      super || build_alternate_identifier
    end

    def declared_attached_files
      { descMetadata: descMetadata, properties: properties, fullMetadata: fullMetadata }
    end

    def attached_files
      @attached_files ||= ActiveSupport::HashWithIndifferentAccess.new(declared_attached_files)
    end

    def properties
      super || build_properties
    end

    # Returns whether the object has a status of 'published'
    #
    # @return [Boolean] true if status is published
    def published?
      status == 'published'
    end

    private

    def delete_objects
      if collection?
        if governed_items.count > 0
          governed_items.each { |g| g.destroy }
        end
      end
    end

    def delete_files
      if generic_files.count > 0
        generic_files.each { |gf| gf.destroy }
      end
    end

    def delete_bucket
      storage = StorageService.new
      storage.delete_bucket(noid)
    end
  end # Class
end # Module DRI
