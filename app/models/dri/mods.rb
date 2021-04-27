# DRI namespace
module DRI
  # Implementation of DRI Mods digital objects
  class Mods < DRI::DigitalObject
    include DRI::ModelSupport::ModsSupport

    has_one :descMetadata, class_name: 'DRI::Metadata::Mods', as: :describable, autosave: true

    # MODS record identifier mods:identifier[@type='local'], not multi-valued
    delegate :mods_id_local=, to: :descMetadata
    # MODS record asset identifier used to sort pages/sequenced items
    delegate :id_asset=, to: :descMetadata
    # MODS rest of identifiers are repeatable
    delegate :identifier, :identifier=, to: :descMetadata
    delegate :identifier_doi, :identifier_doi=, to: :descMetadata
    delegate :identifier_uri, :identifier_uri=, to: :descMetadata

    # Collection attribute + genre type
    delegate :mods_type_collection=, to: :descMetadata
    delegate :mods_genre, :mods_genre=, to: :descMetadata

    # subtitle
    delegate :mods_subtitle, :mods_subtitle=, to: :descMetadata

    # Description
    delegate :desc_abstract, :desc_abstract=, to: :descMetadata
    delegate :desc_toc, :desc_toc=, to: :descMetadata
    delegate :desc_note, :desc_note=, to: :descMetadata
    delegate :desc_physdesc_note, :desc_physdesc_note=, to: :descMetadata
    # delegate :abstract, to: :descMetadata
    # delegate :toc, to: :descMetadata
    # delegate :note_mods_type, to: :descMetadata
    # delegate :note_mods_no_type, to: :descMetadata

    # Rights copyrightMD
    delegate :copyrightmd_rights, :copyrightmd_rights=, to: :descMetadata

    # Source
    delegate :source, :source=, to: :descMetadata
    delegate :source_physical_location, :source_physical_location=, to: :descMetadata
    delegate :source_location, :source_location=, to: :descMetadata

    # Dates
    delegate :date, :date=, to: :descMetadata
    delegate :date_other, :date_other=, to: :descMetadata
    delegate :date_other_start, :date_other_start=, to: :descMetadata
    delegate :date_other_end, :date_other_end=, to: :descMetadata
    delegate :captured_date, :captured_date=, to: :descMetadata
    delegate :captured_date_start, :captured_date_start=, to: :descMetadata
    delegate :captured_date_end, :captured_date_end=, to: :descMetadata
    delegate :issued_date_start, :issued_date_start=, to: :descMetadata
    delegate :issued_date_end, :issued_date_end=, to: :descMetadata
    delegate :creation_date_start, :creation_date_start=, to: :descMetadata
    delegate :creation_date_end, :creation_date_end=, to: :descMetadata

    # Geographical, temporal, name
    delegate :name_coverage, :name_coverage=, to: :descMetadata
    delegate :geographical_coverage, :geographical_coverage=, to: :descMetadata
    delegate :temporal_coverage, :temporal_coverage=, to: :descMetadata
    delegate :subject_date_start, :subject_date_start=, to: :descMetadata
    delegate :subject_date_end, :subject_date_end=, to: :descMetadata
    delegate :geocode_logainm, :geocode_logainm=, to: :descMetadata

    delegate :published_date, :published_date=, to: :descMetadata
    delegate :creation_date, :creation_date=, to: :descMetadata

    delegate :collection?, to: :descMetadata

    class_eval do
      # Roles
      DRI::Vocabulary.marc_relators.map { |s| delegate s.prepend('role_').to_sym, to: :descMetadata }
      # Internal Relationships
      DRI::Vocabulary.mods_relationship_types.map { |s| delegate s.prepend('related_items_ids_').to_sym, s.concat('=').to_sym, to: :descMetadata }
      # External relationships (contain a URI to resources external to DRI)
      DRI::Vocabulary.mods_relationship_types.map { |s| delegate s.prepend('ext_related_items_ids_').to_sym, s.concat('=').to_sym, to: :descMetadata }
    end

    # Disabled for now
    # around_save :create_multiple_records

    def descMetadata
      super || build_descMetadata
    end

    def fullMetadata
      super || build_fullMetadata
    end

    delegate :resource_type, :resource_type=, to: :descMetadata
    delegate :mods_genre, :mods_genre=, to: :descMetadata
    delegate :origin_metadata, :origin_metadata=, to: :descMetadata
    delegate :subject_metadata, :subject_metadata=, to: :descMetadata

    #
    # @return [Array<Symbol>] MODS DRI terms symbols array
    def self.mods_dri_terms
      [
        :title, :creator, :contributor, :desc_abstract, :desc_note,
        :desc_physdesc_note, :desc_toc, :origin_metadata, :rights,
        :subject_metadata, :source_location, :source_physical_location,
        :publisher, :type, :mods_genre, :language, :roles
      ]
    end

    def mods_id_local
      descMetadata.mods_id_local.first
    end

    def mods_type_collection
      descMetadata.mods_type_collection.first
    end

    def id_asset
      descMetadata.id_asset.first
    end

    # AF Override
    # Set the object's attributes
    # @param [Hash] properties the hash with the object's properties
    def attributes=(properties)
      modified_attributes = properties.select { |key, _value| !DRI::Mods.mods_dri_terms.include? key.to_sym }
      super(modified_attributes)

      update_attributes = properties.select { |key, _value| DRI::Mods.mods_dri_terms.include? key.to_sym }
      update_attributes.each { |key, value| send("#{key}=", value) unless value.nil? }

      attached_files[:fullMetadata].content = attached_files[:descMetadata].content
    end

    #
    # @return [Hash] hash with all the values for the MODS DRI editable terms
    def editable_attributes
      editable_attrs = {}

      DRI::Mods.mods_dri_terms.each do |attr|
        editable_attrs[attr] = send(attr.to_s)
      end

      editable_attrs
    end

    # Returns a Hash with all the values for the DRI editable metadata fields
    # to be populated in a UI Edit form
    #
    # @return [Hash] Hash of DRI MODS metadata
    def retrieve_hash_attributes
      retrieved_attributes = descMetadata.retrieve_terms_hash

      retrieved_attributes[:type] = retrieved_attributes.delete(:resource_type) if retrieved_attributes.key?(:resource_type)
      retrieved_attributes
    end

    # Dynamically generate the attribute setters for the marcrelator
    # individual roles methods
    # e.g. role_cre (creator), role_ctb (contributor)
    # def role_cre(values)
    # ...
    # end
    class_eval do
      DRI::Vocabulary.marc_relators.each do |role|
        # name: role_xxx, where xxx is the marcrelator code
        method_name = role.prepend('role_')

        define_method "#{method_name}=" do |values|
          # the descMetadata roles method expect a Hash with
          # 'name', 'type', 'authority' keys
          values_hash = { 'name' => [], 'type' => [], 'authority' => [] }
          values.each do |v|
            values_hash['name'] << v
            values_hash['type'] << method_name
            values_hash['authority'] << ''
          end

          if values.empty?
            values_hash['name'] << ''
            values_hash['type'] << method_name
            values_hash['authority'] << ''
          end

          self.roles = values_hash
        end
      end
    end

    # Roles attribute setter
    #
    # @param [Hash] roles hash with metadata marcrelator values
    # @option roles [Array<String>] :name the metadata values for the marcrelators in :type
    # @option roles [Array<String>] :type the marcrelator codes
    # @option roles [Array<String>] :authority the values for the authority attribute e.g. marcrel
    def roles=(roles)
      descMetadata.roles = roles
    end

    # creator attribute setter (to create the associated metadata elements in the DS XML)
    # @param [Array<String>] creators the array of creator metadata values to set
    def creator=(creators)
      # default marcrel code for creator cre
      descMetadata.role_cre = creators if creators.is_a?(Array)
    end

    # contributor attribute setter (to create the associated metadata elements in the DS XML)
    # @param [Array<String>] contributors the array of contributor metadata values to set
    def contributor=(contributors)
      # default marcrel code for creator ctb
      descMetadata.add_role('ctb', contributors) if contributors.is_a?(Array)
    end

    # origin_metadata attribute setter (to create the associated metadata elements in the DS XML)
    # @param [Array<String>] origin the array of values to set for mods:originInfo metadata
    def origin_metadata=(origin)
      descMetadata.add_origin_metadata(origin)
    end

    # access_condition (rights) attribute setter (to create the associated metadata elements in the DS XML)
    # @param [Hash, Array<String>] statement the array or hash of values to set for mods:accessCondition metadata
    def rights=(statement)
      if statement.is_a? Hash
        # mods:accessCondition contains nested copyrightmd metadata e.g.
        # <mods:accessCondition>
        #   <copyrightMD:copyright copyright.status="copyrighted" publication.status=”published”>
        #     <copyrightMD:rights.holder>Copyright 2014</copyrightMD:rights.holder>
        #     <copyrightMD:general.note>Images are available for single-use</copyrightMD:general.note>
        #   </copyrightMD:copyright>
        # </mods:accessCondition>
        # Expected format: statement = {status: [], rights: [], note: []}
        descMetadata.add_rights(statement)
      else
        # mods:accessCondition contains just text, so statement = Array<String>
        descMetadata.rights = statement
      end
    end

    # TODO: Revise the rights attr getter
    # rights attribute getter
    # @return [Array<String>] the metadata values for rights field
    def rights
      # default to values from mods:accessCondition using
      # copyghtmd schema
      return copyrightmd_rights unless copyrightmd_rights.empty?

      descMetadata.rights
    end

    # subject_metadata attribute setter (to create the associated metadata elements in the DS XML)
    # @param [Array<String>] subjects the array of values to set for mods:subject/mods:topic metadata
    def subject_metadata=(subjects)
      descMetadata.add_subject(subjects)
    end

    # type attribute getter
    # @return [Array<String>] array of type metadata term values
    def type
      descMetadata.resource_type
    end

    # type attribute setter (to create the associated metadata elements in the DS XML)
    # @param [Hash] type the hash of values to set for mods:typeOfResource metadata
    # @option type [Boolean] :collection array of flags to specify whether collection or object record
    # @option type [Array<String>] :content the array of values for the content of mods:typeOfResource
    def type=(type)
      descMetadata.add_type(type)
    end

    # mods_genre attribute setter (to create the associated metadata elements in the DS XML)
    # @param [Hash] genres the hash of values to set for mods:genre metadata
    # @option genres [Boolean] :authority array of authority attribute values for mods:genre
    # @option genres [Array<String>] :content the array of values for the content of mods:genre
    def mods_genre=(genres)
      descMetadata.add_mods_genre(genres)
    end

    # geographical_coverage attribute getter
    # @return [Array<String>] the metadata values for geographical coverage field
    def geographical_coverage
      descMetadata.geographical_coverage | descMetadata.geocode_logainm
    end

    # language attribute setter (to create the associated metadata elements in the DS XML)
    # @param [Hash] languages the hash of values to set for mods:language metadata
    # @option genres [Boolean] :authority array of authority attribute values for mods:genre
    # @option genres [Array<String>] :content the array of values for the content of mods:genre
    def language=(languages)
      descMetadata.add_language(languages)
    end

    # Updates the XML metadata for the object's descMetadata datastream
    # @param [String, File] xml_text String or file containing xml metadata to be updated
    # @param [Boolean] _ingest  true if ingest operation; false if metadata update operation
    # @return [Boolean] true if xml updated successfully; false otherwise
    def update_metadata(xml_text, _ingest = true)
      xml_text = xml_text.read if xml_text.is_a? File

      xml = if xml_text.is_a? Nokogiri::XML::Document
              xml_text
            else
              Nokogiri::XML xml_text
            end

      xml_no_blanks = Nokogiri::XML.parse(xml.to_xml, &:noblanks)

      fullMetadata.ng_xml = xml_no_blanks
      object = split_xml xml_no_blanks
      descMetadata.ng_xml = object

      true
    end

    # If the mods:modsCollection wrapper is used in the XML metadata then
    # remove all MODS records from the XML
    # @param [Nokogiri::XML] xml_text the XML metadata for the object
    # @return [Nokogiri::XML] the modified XML document
    def split_xml(xml_text)
      # This is an individual record, therefore return all XML
      return xml_text if xml_text.search('/mods:modsCollection').empty?

      collection = xml_text.search('/mods:modsCollection')
      mods_records = collection.children

      # Return only the first MODS record;
      # the rest will be created in resque jobs
      record = mods_records.first

      # Need to add the namespace declarations to the mods:mods root element
      # Otherwise the terminology (xpath) won't find the elements
      new_xml = Nokogiri::XML::Builder.new do |xml|
        xml.mods({ 'xmlns:mods' => 'http://www.loc.gov/mods/v3' }, record.namespaces) {
          xml.parent.namespace = xml.parent.namespace_definitions.find(&:href)
          xml << record.children.to_xml
        }
      end

      # Return the first record
      Nokogiri::XML(new_xml.to_xml)
    end

    # For relationships display in the UI, creates Hash where the keys are
    # relationship names, which contain a displayable label and the model metadata field
    # for the given relationship
    #
    # @return [Hash] relationships hash including label/field
    def self.relationships
      {
        preceding: { label: 'Preceding', field: 'related_items_ids_preceding' },
        succeeding: { label: 'Succeeding', field: 'related_items_ids_succeeding' },
        original: { label: 'Has Original', field: 'related_items_ids_original' },
        host: { label: 'Is Part Of', field: 'related_items_ids_host' },
        constituents: { label: 'Has Parts', field: 'related_items_ids_constituent' },
        series: { label: 'Has Series', field: 'related_items_ids_series' },
        other_version: { label: 'Is Version Of', field: 'related_items_ids_otherVersion' },
        other_format: { label: 'Is Format Of', field: 'related_items_ids_otherFormat' },
        referenced_by: { label: 'Is Referenced By', field: 'related_items_ids_isReferencedBy' },
        references: { label: 'References', field: 'related_items_ids_references' },
        review: { label: 'Is Review Of', field: 'related_items_ids_reviewOf' }
      }
    end

    # Return the solr field name for the mods identifier used in metadata MODS relationships
    # i.e. mods_id_local_tesim
    # @return [String] AF solrizer solr index field name
    def self.solr_relationships_field
      Solrizer.solr_name('mods_id_local', :stored_searchable, type: :string)
    end

    private

    def create_multiple_records
      # Do save the object
      yield

      return unless trigger_ingest

      query = fullMetadata.ng_xml.search('//mods:mods')
      return unless new_record? || query.count <= 1

      begin
        DRI.queue.push(CreateModsRecordsJob.new(id))
      rescue => e
        Rails.logger.error(e.message)
      end
    end # end create_multiple_records
  end # class
end # module
