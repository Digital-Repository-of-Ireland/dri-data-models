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
      
  has_many :generic_files, :property => :is_part_of

  has_metadata :name => "extracted", :type => DRI::Metadata::Extracted
  has_attributes :full_text, datastream: :extracted, multiple: true

  def Batch.with_standard(standard, args = {})
   case standard
   when :marc
     Marc.new(args)
   when :qdc
     QualifiedDublinCore.new(args)
   when :ead_collection
     EncodedArchivalDescription.new(:collection, args)
   when :ead_component
     EncodedArchivalDescription.new(:component, args)
   else
     QualifiedDublinCore.new(args)
   end
  end 

  def self.find_or_create(pid)
    begin
      Batch.find(pid)
    rescue ActiveFedora::ObjectNotFoundError
      Batch.create({pid: pid})
    end
  end

  # Unstemmed, searchable, stored
  def noid_indexer
    @noid_indexer ||= Solrizer::Descriptor.new(:text, :indexed, :stored)
  end

  def assert_content_model
    add_relationship(:has_model, self.class.to_class_uri)
    add_relationship(:has_model, self.class.superclass.to_class_uri)
  end

  def update_metadata xml_text
    if (xml_text.is_a? File)
      xml_text = xml_text.read
    end

    descMetadata.ng_xml = xml_text

    return true
  end

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

    # Add title metadata from parent collections
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

end
