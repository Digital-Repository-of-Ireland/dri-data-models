# Namespace for classes and modules that handle DRI digital objects
# extending from active-fedora
#
module DRI
  # DRI Batch, generic DRI digital object
  # Digital objects in DRI that handle the supported metadata standards
  # inherit from this class
  #
  class Batch < ActiveFedora::Base
    include Sufia::ModelMethods
    include Sufia::Noid
    include Sufia::GenericFile::Export
    include DRI::ModelSupport::Properties
    include DRI::ModelSupport::Permissions
    include DRI::ModelSupport::InterchangeableMetadata
    include DRI::ModelSupport::Files
    include DRI::ModelSupport::Collections
    include DRI::ModelSupport::RelationshipsSupport

    after_destroy :delete_bucket

    # one-to-many AF relationship to associate digital assets with their batch object
    has_many :generic_files, class_name: 'DRI::GenericFile', inverse_of: :batch, dependent: :destroy
    # one-to-many AF relationship to associate documentation objects
    has_many :documentation_objects, class_name: 'DRI::Documentation', as: :documentation_for

    # Declare a 'extracted' DS, of the following type
    # Unused for NOW
    contains 'extracted', class_name: 'DRI::Metadata::Extracted'

    # Declare the attributes of 'extracted' DS - 'full_text' - and that the DS is repeatable
    # Unused for NOW
    property :full_text, delegate_to: 'extracted', multiple: true

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
       EncodedArchivalDescription.new(:collection, args)
      when :ead_component
        EncodedArchivalDescription.new(:component, args)
      when :mods
        Mods.new(args)
      when :documentation
        Documentation.new(args)
      else
        QualifiedDublinCore.new(args)
      end
    end

    # Retrieves a digital object from fedora given its pid; creates
    # a new object if object not found
    #
    # @param pid [String] the pid of the object to retrieve
    # @return [DRI::Batch] the digital object.
    def self.find_or_create(pid)
      DRI::Batch.find(pid)
    rescue ActiveFedora::ObjectNotFoundError
      DRI::Batch.create(id: pid)
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
    def assert_content_model
      self.has_model = [self.class.to_s, self.class.superclass.to_s]
    end

    # Return a Hash representation of this object where keys
    # in the hash are appropriate Solr field names.
    #
    # @param solr_doc [Hash] hash to insert the fields into
    # @param _opts [Hash] options hash
    # @return [Hash] the solr document to be indexed
    def to_solr(solr_doc = {}, _opts = {})
      solr_doc = super(solr_doc)

      solr_doc.merge! collections_to_solr
      solr_doc.merge! object_types_to_solr
      solr_doc.merge! file_metadata_to_solr

      metadata_streams.each do |m|
        solr_doc.merge! m.to_solr
      end

      solr_doc.merge!('all_text_timv' => full_text)

      solr_doc
    end

    # Add object types as a hierarchical tree into the Solr fields
    #
    # @param solr_doc [Hash] hash to insert the fields into
    # @return [Hash] the solr document to be indexed
    def object_types_to_solr(solr_doc = {})
      object_types = []

      type.each { |cat| object_types.push cat.split.map(&:capitalize)*' ' }
      object_types.push('Unknown') if object_types.count < 1

      solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('object_type', :facetable) => object_types)
      solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('object_type', :displayable) => object_types)

      solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('type', DRI::Metadata::Descriptors.cleaned_facetable) => type)
      solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('type', DRI::Metadata::Descriptors.cleaned_searchable) => type)
      solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('type', DRI::Metadata::Descriptors.cleaned_displayable) => type)

      if rights.empty?
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('rights', :stored_searchable) => ['No rights statement'])
      end

      solr_doc
    end

    # Returns whether the object has a status of 'published'
    #
    # @return [Boolean] true if status is published
    def published?
      status == 'published'
    end

    private

    def delete_bucket
      storage = StorageService.new
      storage.delete_bucket(id)
    end
  end # Class Batch
end # Module DRI
