module DRI
  class Batch < ActiveFedora::Base
    include ActiveFedora::Auditable
    include Sufia::ModelMethods
    include Sufia::Noid
    include Sufia::GenericFile::Export
    include Sufia::GenericFile::ReloadOnSave
    include DRI::ModelSupport::Properties
    include DRI::ModelSupport::Permissions
    include DRI::ModelSupport::InterchangeableMetadata
    include DRI::ModelSupport::Files
    include DRI::ModelSupport::Collections
    include DRI::ModelSupport::RelationshipsSupport

    has_many :generic_files, :class_name => "DRI::GenericFile", :property => :is_part_of, :dependent => :destroy

    # dependent: :destroy -> remove the documentation object if the collection is deleted
    has_many :documentation_objects, :class_name => "DRI::Documentation", :property => :is_description_of, :dependent => :destroy

    # Declare a 'extracted' DS, of the following type
    has_metadata :name => "extracted", :type => DRI::Metadata::Extracted

    # Declare the attributes of 'extracted' DS - 'full_text' - and that the DS is repeatable
    has_attributes :full_text, datastream: :extracted, multiple: true

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

    def self.find_or_create(pid)
      begin
        DRI::Batch.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
        DRI::Batch.create({pid: pid})
      end
    end

    # Initialises the Solr index field (and its type) for this object
    def noid_indexer
      # Unstemmed, searchable, stored
      @noid_indexer ||= Solrizer::Descriptor.new(:text, :indexed, :stored)
    end

    def assert_content_model
      add_relationship(:has_model, self.class.to_class_uri)
      add_relationship(:has_model, self.class.superclass.to_class_uri)
    end

    # Updates the metadata class of the current digital object in case we are now working
    # with a different metadata standard
    # @param[String,File] xml_text xml metadata content or a File
    # @return[boolean] true if op successful
    # Note: Use this in preference over the setting xml directly in the OmDatastreams
    def update_metadata xml_text
      if (xml_text.is_a? File)
        xml_text = xml_text.read
      end

      descMetadata.ng_xml = xml_text

      return true
    end

    # Performs the indexing of this object into Solr
    # @param solr_doc []
    def to_solr(solr_doc={}, opts={})
      solr_doc = super(solr_doc, opts)

      solr_doc[Solrizer.solr_name('noid', noid_indexer)] = noid

      solr_doc.merge!collections_to_solr
      solr_doc.merge!object_types_to_solr
      solr_doc.merge!file_metadata_to_solr

      solr_doc.merge!('all_text_timv' => full_text)

      return solr_doc
    end

    # Indexing object types as a hierarchical tree
    def object_types_to_solr(solr_doc=Hash.new)
      object_types = []

      self.descMetadata.type.each do | curr_category |
        object_types.push curr_category.split.map(&:capitalize)*' '
      end

      if object_types.count < 1
        object_types.push "Unknown"
      end
      solr_doc.merge!(solr_name('object_type', :facetable) => object_types)
      solr_doc.merge!(solr_name('object_type', :displayable) => object_types)
      if rights.empty?
        solr_doc.merge!(solr_name('rights', :stored_searchable) => ['No rights statement'])
      end

      solr_doc
    end

    # Relationships Methods

    #def process_collection_relationships
    #end

    #def process_relationships()
    #end

    #def get_relationships_names
      # Empty Array - NO DRI specific relationships for now Overriden
      #return {}
    #end

  end # Class Batch
end # Module DRI
