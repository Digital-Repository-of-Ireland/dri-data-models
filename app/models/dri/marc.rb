# DRI namespace
module DRI
  # Implementation of DRI Marc digital objects extending from DRI::Batch
  class Marc < DRI::Batch
    include DRI::ModelSupport::MarcSupport

    contains 'descMetadata', class_name: 'DRI::Metadata::Marc'

    property :leader, delegate_to: 'descMetadata', multiple: false
    property :controlfield, delegate_to: 'descMetadata', multiple: true
    property :controlfield_tag, delegate_to: 'descMetadata', multiple: true
    property :datafield, delegate_to: 'descMetadata', multiple: true
    property :datafield_tag, delegate_to: 'descMetadata', multiple: true
    property :datafield_ind1, delegate_to: 'descMetadata', multiple: true
    property :datafield_ind2, delegate_to: 'descMetadata', multiple: true

    # MARC record identifier used for internal rels target,
    # NOT multi-valued
    property :marc_id, delegate_to: 'descMetadata', multiple: false
    # MARC record asset identifier used to sort pages/sequenced items
    property :id_asset, delegate_to: 'descMetadata', multiple: false

    # MARC Relationships, mapped from QDC predicate properties
    # Mapped attributes for getting relational information from metadata
    # Internal Relationships
    # 775: Other Edition Entry; Mapped to QDC: isVersionOf
    property :relation_ids_isVersionOf, delegate_to: 'descMetadata', multiple: true
    # 776: Additional Physical Form Entry; Mapped to QDC: isFormatOf
    property :relation_ids_isFormatOf, delegate_to: 'descMetadata', multiple: true
    # 787: Other Relationship Entry; Mapped to DC: relation
    property :relation_ids_relation, delegate_to: 'descMetadata', multiple: true
    # Tag 780 - Preceding Entry (R); Mapped to MODS: preceding
    property :relation_ids_preceding, delegate_to: 'descMetadata', multiple: true
    property :relation_ids_succeeding, delegate_to: 'descMetadata', multiple: true

    property :related_material, delegate_to: 'descMetadata', multiple: true
    property :alternative_form, delegate_to: 'descMetadata', multiple: true

    # Disabled below - metadata object update triggers
    # the creation of duplicated objects
    # around_save :create_multiple_records

    # Override constructor
    def initialize(params = {})
      params[:desc_metadata_class] = 'DRI::Metadata::Marc'
      super(params)
    end

    # type attribute getter
    # @return [Array<String>] array of type metadata term values
    def type
      descMetadata.type
    end

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
      ActiveFedora::SolrQueryBuilder.solr_name('marc_id', :stored_searchable, type: :string)
    end

    # Return a Hash including all the PIDs of fedora objects by relationship type
    # @return [Hash] the hash of MARC relationships with the Fedora PIDs of the related objects
    def get_relationships_records
      { related: retrieve_relation_records(send(self.class.relationships[:related][:field]),
                                           self.class.solr_relationships_field),
        is_version: retrieve_relation_records(send(self.class.relationships[:is_version][:field]),
                                              self.class.solr_relationships_field),
        is_format: retrieve_relation_records(send(self.class.relationships[:is_format][:field]),
                                             self.class.solr_relationships_field),
        preceding: retrieve_relation_records(send(self.class.relationships[:preceding][:field]),
                                             self.class.solr_relationships_field),
        succeeding: retrieve_relation_records(send(self.class.relationships[:succeeding][:field]),
                                              self.class.solr_relationships_field)
      }
    end

    private

    def create_multiple_records
      yield # save

      full_metadata_no_ns = fullMetadata.ng_xml.clone
      full_metadata_no_ns.remove_namespaces!

      return if new_record? || full_metadata_no_ns.search('//record').count <= 1

      begin
        Sufia.queue.push(CreateMarcRecordsJob.new(id))
      rescue Exception => e
        Rails.logger.error(e.message)
      end
    end
  end # class
end # module
