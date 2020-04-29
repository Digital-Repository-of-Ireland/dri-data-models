# DRI namespace
module DRI
  # Implementation of DRI Marc digital objects
  class Marc < DRI::DigitalObject
    include DRI::ModelSupport::MarcSupport

    has_one :descMetadata, class_name: 'DRI::Metadata::Marc', as: :describable, autosave: true

    delegate :leader=, to: :descMetadata

    delegate :controlfield, to: :descMetadata
    delegate :controlfield_tag, to: :descMetadata
    delegate :datafield, to: :descMetadata
    delegate :datafield_tag, to: :descMetadata
    delegate :datafield_ind1, to: :descMetadata
    delegate :datafield_ind2, to: :descMetadata

    # MARC record identifier used for internal rels target,
    # NOT multi-valued
    delegate :marc_id=, to: :descMetadata

    # MARC record asset identifier used to sort pages/sequenced items
    delegate :id_asset=, to: :descMetadata

    # MARC Relationships, mapped from QDC predicate properties
    # Mapped attributes for getting relational information from metadata
    # Internal Relationships
    # 775: Other Edition Entry; Mapped to QDC: isVersionOf
    delegate :relation_ids_isVersionOf, to: :descMetadata

    # 776: Additional Physical Form Entry; Mapped to QDC: isFormatOf
    delegate :relation_ids_isFormatOf, to: :descMetadata
    # 787: Other Relationship Entry; Mapped to DC: relation
    delegate :relation_ids_relation, to: :descMetadata
    # Tag 780 - Preceding Entry (R); Mapped to MODS: preceding
    delegate :relation_ids_preceding, to: :descMetadata
    delegate :relation_ids_succeeding, to: :descMetadata

    delegate :related_material, to: :descMetadata
    delegate :alternative_form, to: :descMetadata

    delegate :date, to: :descMetadata
    delegate :published_date, to: :descMetadata

    def id_asset
      descMetadata.id_asset.first
    end

    def leader
      descMetadata.leader.first
    end

    def descMetadata
      super || build_descMetadata
    end

    def fullMetadata
      super || build_fullMetadata
    end

    def marc_id
      descMetadata.marc_id.first
    end

    # type attribute getter
    # @return [Array<String>] array of type metadata term values
    def type
      descMetadata.type
    end

    # Updates the XML metadata for the object's descMetadata datastream
    # @param [String, File] xml_text String or file containing xml metadata to be updated
    # @param [Boolean] _ingest  true if ingest operation; false if metadata update operation
    # @return [Boolean] true if xml updated successfully; false otherwise
    def update_metadata(xml_text, _ingest = true)
      xml_text = xml_text.read if xml_text.is_a? File

      if xml_text.is_a? Nokogiri::XML::Document
        xml = xml_text
      else
        xml = Nokogiri::XML xml_text
      end

      xml_no_blanks = Nokogiri::XML.parse(xml.to_xml, &:noblanks)

      fullMetadata.ng_xml = xml_no_blanks
      object = split_xml(xml_no_blanks.remove_namespaces!)
      descMetadata.ng_xml = object

      true
    end

    # If the marc:collection wrapper is used in the XML metadata then
    # remove all MODS records from the XML
    # @param [Nokogiri::XML] xml_text the XML metadata for the object
    # @return [Nokogiri::XML] the modified XML document
    def split_xml(xml_text)
      # If collection wrapper present, the first object will have
      # the first marc:record and we then process the rest when saving
      collection = xml_text.search('//collection')

      if collection.empty?
        record = xml_text
      else
        records = collection.children
        record = records[0]
      end

      record.to_xml
    end

    # Override AF attributes setter
    def attributes=(properties)
      controlfields = properties.delete('controlfield')
      datafields = properties.delete('datafield')
      super(properties)

      descMetadata.add_controlfields(controlfields) unless controlfields.nil?
      descMetadata.add_datafields(datafields) unless datafields.nil?
    end

    # For relationships display in the UI, creates Hash where the keys are
    # relationship names, which contain a displayable label and the model metadata field
    # for the given relationship
    #
    # @return [Hash] relationships hash including label/field
    def self.relationships
      { related: { label: 'Is Related To', field: 'relation_ids_relation' },
        is_version: { label: 'Is Version Of', field: 'relation_ids_isVersionOf' },
        is_format: { label: 'Is Format Of', field: 'relation_ids_isFormatOf' },
        preceding: { label: 'Preceding', field: 'relation_ids_preceding' },
        succeeding: { label: 'Succeeding', field: 'relation_ids_succeeding' }
      }
    end

    # Return the solr field name for the mods identifier used in metadata MARC relationships
    # i.e. marc_id_tesim
    # @return [String] AF solrizer solr index field name
    def self.solr_relationships_field
      Solrizer.solr_name('marc_id', :stored_searchable, type: :string)
    end

    private

    def create_multiple_records
      yield # save

      full_metadata_no_ns = fullMetadata.ng_xml.clone
      full_metadata_no_ns.remove_namespaces!

      return if new_record? || full_metadata_no_ns.search('//record').count <= 1

      begin
        DRI.queue.push(CreateMarcRecordsJob.new(id))
      rescue Exception => e
        Rails.logger.error(e.message)
      end
    end
  end # class
end # module
