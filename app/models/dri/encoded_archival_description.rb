module DRI
  class EncodedArchivalDescription < DRI::Batch

    include DRI::ModelSupport::EadSupport

    # Specific EAD terms mapped
    # Identifier
    has_attributes :identifier, datastream: :descMetadata, multiple: false
    #has_attributes :unitid, datastream: :descMetadata, multiple: false
    #has_attributes :eadid, datastream: :descMetadata, multiple: false
    has_attributes :repository_code, datastream: :descMetadata, multiple: false
    has_attributes :country_code, datastream: :descMetadata, multiple: false
    has_attributes :identifier_id, datastream: :descMetadata, multiple: true
    has_attributes :identifier_url, datastream: :descMetadata, multiple: true
    has_attributes :identifier_public_id, datastream: :descMetadata, multiple: true

    # Description
    has_attributes :abstract, datastream: :descMetadata, multiple: false
    has_attributes :bioghist, datastream: :descMetadata, multiple: false
    has_attributes :scope_content, datastream: :descMetadata, multiple: false
    has_attributes :note, datastream: :descMetadata, multiple: true

    # Types
    #has_attributes :type, datastream: :descMetadata, multiple: true
    has_attributes :type_ead, datastream: :descMetadata, multiple: true
    has_attributes :ead_level, datastream: :descMetadata, multiple: false

    #has_attributes :physdesc, datastream: :descMetadata, multiple: true

    # Files, description
    has_attributes :dao, datastream: :descMetadata, multiple: true
    has_attributes :dao_href, datastream: :descMetadata, multiple: true
    has_attributes :dao_desc, datastream: :descMetadata, multiple: true

    # EAD Elements with multiple mappings
    #has_attributes :language_did, datastream: :descMetadata, multiple: true
    #has_attributes :creation_date_profiledesc, datastream: :descMetadata, multiple: true
    has_attributes :access_restrict, datastream: :descMetadata, multiple: true
    has_attributes :subject_archdesc, datastream: :descMetadata, multiple: true

    # Coverage: name, geographical, location, temporal
    has_attributes :name_coverage, datastream: :descMetadata, multiple: true
    has_attributes :geographical_coverage, datastream: :descMetadata, multiple: true
    has_attributes :persname_coverage, datastream: :descMetadata, multiple: true
    has_attributes :corpname_coverage, datastream: :descMetadata, multiple: true
    has_attributes :temporal_coverage, datastream: :descMetadata, multiple: true

    around_save :synchronize_if_changed

    def initialize(type, args = {})
      case type
      when :collection
        metadata_class = "DRI::Metadata::EncodedArchivalDescription"
      else
        metadata_class = "DRI::Metadata::EncodedArchivalDescriptionComponent"
      end
      args[:desc_metadata_class] = metadata_class

      super(args)
    end

    def self.find_or_create(pid)
      begin
        DRI::EncodedArchivalDescription.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
        DRI::EncodedArchivalDescription.create({pid: pid})
      end
    end

    def attributes=(properties)
      super(properties)
    end

    # Override from collection.rb adding EAD-specific solr additions
    def collections_to_solr(solr_doc=Hash.new)
      solr_doc = super(solr_doc)
      if descMetadata.class == DRI::Metadata::EncodedArchivalDescriptionComponent && previous_sibling == nil
        solr_doc.merge!(solr_name('is_first_sibling', :stored_searchable) => "1")
      end
      solr_doc
    end

    # Indexing object types as a hierarchical tree
    def object_types_to_solr(solr_doc=Hash.new)

      # Add title metadata from parent collections
      object_types = []

      #main_category = nil

      self.descMetadata.type.each do | curr_category |
        object_types.push curr_category.split.map(&:capitalize)*' '
      end

      if object_types.empty?
        case descMetadata
          when DRI::Metadata::EncodedArchivalDescriptionComponent
            if (descMetadata.collection?)
              object_types.push "Collection"
            end
            object_types.push ead_level.split.map(&:capitalize)*' '
        when DRI::Metadata::EncodedArchivalDescription
          object_types.push "Collection"
        end
      end

      if object_types.count < 1
        object_types.push "Unknown"
      end
      solr_doc.merge!(solr_name('object_type', :facetable) => object_types)
      solr_doc.merge!(solr_name('object_type', :displayable) => object_types)

      # TODO Implementing rights inheritance from parent collections if not present
      #if rights.empty?
      #  solr_doc.merge!(solr_name('rights', :stored_searchable) => ['No rights statement'])
      #end

      solr_doc
    end

    def update_metadata xml_text
      if (xml_text.is_a? File)
        xml_text = xml_text.read
      end

      fullMetadata.ng_xml = xml_text
      xml_text = split_ead_xml xml_text, desc_metadata_class

      descMetadata.ng_xml = xml_text

      return true
    end

    # If this is EAD, put the full XML in fullMetadata and
    # return XML with the component's children removed
    def split_ead_xml xml_text, xml_type
      if (xml_text.is_a? Nokogiri::XML::Document)
        xml = xml_text
      else
        xml = Nokogiri::XML xml_text
      end

      if (xml_type == "DRI::Metadata::EncodedArchivalDescription")
        xml.xpath("/ead/archdesc/dsc/*").remove
      else
        xml.xpath("/*/dsc/*").remove
      end

      return xml
    end

    def synchronize_if_changed
      content_changed = false

      if (self.descMetadata.synchronize_metadata_on_save == true)
        content_changed = self.descMetadata.changed?
      end

      yield

      if content_changed && !new_record?
        Sufia.queue.push(SynchronizeChildrenToMetadataJob.new(self.pid))
      end
    end

  end # class
end # module
