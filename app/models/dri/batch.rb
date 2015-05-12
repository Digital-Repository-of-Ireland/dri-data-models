module DRI
  class Batch < ActiveFedora::Base
    include Sufia::ModelMethods
    include Sufia::Noid
    include Sufia::GenericFile::Export
    include DRI::ModelSupport::Properties
    include DRI::ModelSupport::Permissions
    include DRI::ModelSupport::InterchangeableMetadata
    include DRI::ModelSupport::Files
    include DRI::ModelSupport::Collections
  
    has_many_versions

    has_many :generic_files, class_name: "DRI::GenericFile", as: :batch

    # dependent: :destroy -> remove the documentation object if the collection is deleted
    has_many :documentation_objects, class_name: "DRI::Documentation", as: :documentation_for, dependent: :destroy

    # dependent: :destroy -> remove the documentation object if the collection is deleted
    has_many :documentation_objects, :class_name => "DRI::Documentation", :dependent => :destroy, :property => :is_description_of

    # Declare a 'extracted' DS, of the following type
    contains "extracted", class_name: 'DRI::Metadata::Extracted'

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
      else
        QualifiedDublinCore.new(args)
      end
    end 

    def self.find_or_create(pid)
      begin
        DRI::Batch.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
        DRI::Batch.create({id: pid})
      end
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

    def assert_content_model
      self.has_model = [self.class.to_s, self.class.superclass.to_s]
    end

    def to_solr(solr_doc=Hash.new, opts={})
      solr_doc = super(solr_doc)

      solr_doc.merge!collections_to_solr
      solr_doc.merge!object_types_to_solr
      solr_doc.merge!file_metadata_to_solr

      self.metadata_streams.each do |m|
        solr_doc.merge!m.to_solr
      end

      solr_doc.merge!('all_text_timv' => full_text)

      solr_doc
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
      solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('object_type', :facetable) => object_types)
      solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('object_type', :displayable) => object_types)
      if rights.empty?
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('rights', :stored_searchable) => ['No rights statement'])
      end

      solr_doc
    end

    # Relationships Methods

    def process_collection_relationships
    end

    def process_relationships()
    end

    def add_dm_relationship
    end

    def get_relationships_names
      # Empty Array - NO DRI specific relationships for now Overriden
      return {}
    end

  end # Class Batch
end # Module DRI
