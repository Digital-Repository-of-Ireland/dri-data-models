# DRI namespace
module DRI
  # Implementation of DRI EAD digital objects extending from DRI::Batch
  class EncodedArchivalDescription < DRI::Batch
    include DRI::ModelSupport::EadSupport

    # Specific EAD terms mapped
    # Identifier - for ead header maps to eadid; for components to unitid
    # (!) Important - change on identifier for components: repeatable
    property :identifier, delegate_to: 'descMetadata', multiple: true
    property :identifier_id, delegate_to: 'descMetadata', multiple: false
    property :repository_code, delegate_to: 'descMetadata', multiple: false
    property :country_code, delegate_to: 'descMetadata', multiple: false

    # ISO Dates
    property :creation_date_idx, delegate_to: 'descMetadata', multiple: true
    property :published_date_idx, delegate_to: 'descMetadata', multiple: true
    property :temporal_coverage_idx, delegate_to: 'descMetadata', multiple: true

    # Description properties
    property :desc_abstract, delegate_to: 'descMetadata', multiple: false
    property :desc_biog_hist, delegate_to: 'descMetadata', multiple: true
    property :desc_scope_content, delegate_to: 'descMetadata', multiple: true
    property :desc_dao_desc, delegate_to: 'descMetadata', multiple: true
    
    # Subjects
    property :name_subject, delegate_to: 'descMetadata', multiple: true
    property :persname_subject, delegate_to: 'descMetadata', multiple: true
    property :corpname_subject, delegate_to: 'descMetadata', multiple: true
    property :famname_subject, delegate_to: 'descMetadata', multiple: true
    property :geogname_subject, delegate_to: 'descMetadata', multiple: true

    # Types
    property :ead_level, delegate_to: 'descMetadata', multiple: false
    property :ead_level_other, delegate_to: 'descMetadata', multiple: false

    # Files, description
    property :dao_proxy, delegate_to: 'descMetadata', multiple: true
    property :dao_href_proxy, delegate_to: 'descMetadata', multiple: true
    property :dao_desc_proxy, delegate_to: 'descMetadata', multiple: true

    # Coverage: name, geographical, location, temporal
    property :name_coverage, delegate_to: 'descMetadata', multiple: true
    property :geographical_coverage, delegate_to: 'descMetadata', multiple: true
    property :geogname_coverage_access, delegate_to: 'descMetadata', multiple: true
    property :temporal_coverage, delegate_to: 'descMetadata', multiple: true

    # Related Material
    # The <relatedmaterial> element is comparable to ISAD(G)
    # data element 3.5.3 and MARC field 544 with indicator 1
    property :related_material, delegate_to: 'descMetadata', multiple: true

    # Alternative Form Available
    property :alternative_form, delegate_to: 'descMetadata', multiple: true

    property :resource_type, delegate_to: 'descMetadata', multiple: true

    property :geocode_point, delegate_to: 'descMetadata', multiple: true
    property :geocode_box, delegate_to: 'descMetadata', multiple: true
    property :geocode_logainm, delegate_to: 'descMetadata', multiple: true
    property :format, delegate_to: 'descMetadata', multiple: true

    around_save :synchronize_if_changed # trigger EAD children creation

    # Override constructor
    def initialize(type, args = {})
      case type
      when :collection
        metadata_class = 'DRI::Metadata::EncodedArchivalDescription'
      else
        metadata_class = 'DRI::Metadata::EncodedArchivalDescriptionComponent'
      end
      args[:desc_metadata_class] = metadata_class

      super(args)
    end

    # Retrieve an existing Fedora DRI::EncodedArchivalDescription object;
    # creates a new one if object not found for a given PID
    #
    # @param [String] pid the object's PID
    # @return [DRI::EncodedArchivalDescription] the retrieved Fedora object; new object if not found
    def self.find_or_create(pid)
      DRI::EncodedArchivalDescription.find(pid)
    rescue ActiveFedora::ObjectNotFoundError
      DRI::EncodedArchivalDescription.create(id: pid)
    end

    #
    # @return [Array<Symbol>] EAD DRI terms symbols array
    def self.ead_dri_terms
      [:title, :creator, :contributor, :desc_scope_content, :desc_abstract, :desc_biog_hist,
       :creation_date, :published_date, :name_coverage, :temporal_coverage,
       :rights, :subject, :name_subject, :persname_subject, :corpname_subject,
       :geogname_subject, :geogname_coverage_access, :famname_subject, :publisher, :resource_type,
       :related_material, :alternative_form, :language, :format
      ]
    end

    # AF Override
    # Update the object's properties, and sets the trigger_update flag to synchonise EAD parent
    # metadata when updating the object's metadata
    # @see DRI::ModelSupport::EadSupport#trigger_update
    # @param [Hash] properties the hash with the object's properties
    def attributes=(properties)
      updated_props = properties.clone

      # When updating from DRI form
      # replace type attribute key with resource_type
      updated_props.keys.each do |k|
        next if k.to_sym != :type

        updated_props[:resource_type] = updated_props[k]
        updated_props.delete(k)
        break
      end

      modified_attributes = updated_props.select { |key, _value| !DRI::EncodedArchivalDescription.ead_dri_terms.include? key.to_sym }
      super(modified_attributes)

      update_attributes = updated_props.select { |key, _value| DRI::EncodedArchivalDescription.ead_dri_terms.include? key.to_sym }
      self.trigger_update = true unless update_attributes.empty?
      update_attributes.each { |key, value| self.send("#{key}=", value) unless value.nil? }
    end

    #
    # @return [Hash] hash with all the values for the EAD DRI editable terms
    def editable_attributes
      editable_attrs = {}
      DRI::EncodedArchivalDescription.ead_dri_terms.each do |attr|
        editable_attrs[attr] = send("#{attr}")
      end

      editable_attrs
    end

    # Type attribute getter
    #
    # @return [Array<String>] the array of metadata type values
    def type
      descMetadata.resource_type
    end

    # Type attribute setter
    # @param [Array<String>] type the array of metadata type values to set
    def type=(type)
      self.resource_type = type
    end

    # Returns a Hash with all the values for the DRI editable metadata fields
    # to be populated in a UI Edit form
    #
    # @return [Hash] Hash of DRI EAD metadata
    def retrieve_hash_attributes
      descMetadata.retrieve_terms_hash
    end

    # Creator attribute setter (to create the associated metadata elements in the DS XML)
    # @param creators [Hash] the hash of metadata values for creators
    # @option creators [Array<String>] :display the content for the creator nodes
    # @option creators [Array<String>] :role the values for the role attribute for creator nodes
    # @option creators [Array<String>] :tag the tag name to use in creator nodes
    def creator=(creators)
      descMetadata.add_creator(creators)
    end

    # contributor attribute setter (to create the associated metadata elements in the DS XML)
    # @param [Array<String>] contributors the array of contributor metadata values to set
    def contributor=(contributors)
      descMetadata.add_contributor(contributors)
    end

    # desc_scope_content attribute setter (to create the associated metadata elements in the DS XML)
    # @param [Array<String>] descriptions the array of scope content metadata values to set
    def desc_scope_content=(descriptions)
      descMetadata.add_desc_scope_content(descriptions)
    end

    # desc_abstract attribute setter (to create the associated metadata elements in the DS XML)
    # @param [Array<String>] descriptions the array of abstract metadata values to set
    def desc_abstract=(descriptions)
      descMetadata.add_desc_abstract(descriptions)
    end

    # desc_biog_hist attribute setter (to create the associated metadata elements in the DS XML)
    # @param [Array<String>] descriptions the array of biographical history metadata values to set
    def desc_biog_hist=(descriptions)
      descMetadata.add_desc_biog_hist(descriptions)
    end

    # creation_date attribute setter (to create the associated metadata elements in the DS XML)
    #
    # @param [Hash] dates hash of creation date metadata values to set
    # @option dates [Array<String>] :display array of metadata values for date display
    # @option dates [Array<String>] :normal array of metadata values encoded in iso8601 for index
    def creation_date=(dates)
      descMetadata.add_creation_date(dates) unless dates.empty?
    end

    # published_date attribute setter (to create the associated metadata elements in the DS XML)
    #
    # @param [Hash] dates hash of published date metadata values to set
    # @option dates [Array<String>] :display array of metadata values for date display
    # @option dates [Array<String>] :normal array of metadata values encoded in iso8601 for index
    def published_date=(dates)
      descMetadata.add_published_date(dates) unless dates.empty?
    end

    # temporal_coverage attribute setter (to create the associated metadata elements in the DS XML)
    # @param [Hash] dates hash of temporal coverage metadata values to set
    # @option dates [Array<String>] :display array of metadata values for date display
    # @option dates [Array<String>] :normal array of metadata values encoded in iso8601 for index
    # @option dates [Array<String>] :datechar array of metadata values specifying the type of date
    def temporal_coverage=(dates)
      descMetadata.add_temporal_coverage(dates) unless dates.empty?
    end

    # name_coverage attribute setter (to create the associated metadata elements in the DS XML)
    # @param [Array<String>] people the array of name coverage metadata values to set
    # @option people [Array<String>] :display the content for the nodes
    # @option people [Array<String>] :role the role attributes for the nodes
    # @option people [Array<String>] :tag the names of the tags to use when creating the XML elements
    def name_coverage=(people)
      descMetadata.add_name_coverage(people) unless people.empty?
    end

    # alternative_form attribute setter (to create the associated metadata elements in the DS XML)
    # @param [Array<String>] materials the array of alternative form metadata values to set
    def alternative_form=(materials)
      descMetadata.add_alternative_form(materials) unless materials.empty?
    end

    # related_material attribute setter (to create the associated metadata elements in the DS XML)
    # @param [Array<String>] materials the array of related material metadata values to set
    def related_material=(materials)
      descMetadata.add_related_material(materials) unless materials.empty?
    end

    # geogname_coverage_access attribute setter (to create the associated metadata elements in the DS XML)
    # @param [Hash] locations hash of geographical coverage metadata values to set
    # @option locations [Array<String>] :display the content for the nodes
    # @option locations [Array<String>] :role the role attributes for the nodes
    # @option locations [Array<String>] :tag the names of the tags to use when creating the XML elements
    def geogname_coverage_access=(locations)
      descMetadata.add_geogname_coverage_access(locations) unless locations.empty?
    end

    # language attribute setter (to create the associated metadata elements in the DS XML)
    # @param [Hash] languages hash of language metadata values to set
    # @option languages [Array<String>] :langcode the iso639-2b code attribute values for the nodes
    # @option languages [Array<String>] :text the displayable language names for the nodes
    def language=(languages)
      descMetadata.add_language(languages) unless languages.empty?
    end

    # Override from collection.rb adding EAD-specific solr additions
    def collections_to_solr(solr_doc = {})
      solr_doc = super(solr_doc)

      if descMetadata.is_a?(DRI::Metadata::EncodedArchivalDescriptionComponent) && previous_sibling.nil?
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('is_first_sibling', :stored_searchable) => '1')
      end

      solr_doc
    end

    # Override from files.rb adding EAD-specific solr additions
    def file_metadata_to_solr(solr_doc = {})
      solr_doc = super(solr_doc)

      file_type = []
      file_type_display = []

      return solr_doc unless collection?

      file_type.push('collection')

      if !root_collection? && !ead_level.blank?
        file_type_display.push ead_level.strip.capitalize
      else
        file_type_display.push('Collection')
      end

      solr_doc
    end

    # Indexing object types as a hierarchical tree
    def object_types_to_solr(solr_doc = {})
      # Add title metadata from parent collections
      object_types = []

      descMetadata.resource_type.each do |curr_category|
        object_types.push(curr_category.split.map(&:capitalize) * ' ')
      end

      if object_types.empty?
        case descMetadata
        when DRI::Metadata::EncodedArchivalDescriptionComponent
          object_types.push('Collection') if descMetadata.collection?

          if ead_level.include? 'otherlevel'
            object_types.push(ead_level_other.split.map(&:capitalize) * ' ')
          else
            object_types.push(ead_level.split.map(&:capitalize) * ' ')
          end
        when DRI::Metadata::EncodedArchivalDescription
          object_types.push('Collection')
        end
      end

      object_types.push('Unknown') if object_types.count < 1

      solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('object_type', :facetable) => object_types)
      solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('object_type', :displayable) => object_types)

      solr_doc
    end

    # Updates the XML metadata for the object's descMetadata datastream
    # @param [String, File] xml_text String or file containing xml metadata to be updated
    # @param [Boolean] ingest  true if ingest operation; false if metadata update operation
    # @return [Boolean] true if xml updated successfully; false otherwise
    def update_metadata(xml_text, ingest=true)
      # Differentiate between ingest and individual object update
      ingest ? (self.trigger_ingest = true) : (self.trigger_update = true)

      xml_text = xml_text.read if xml_text.is_a?(File)

      if ingest
        fullMetadata.ng_xml = xml_text
        xml_text = split_ead_xml(xml_text, desc_metadata_class)

        descMetadata.ng_xml = xml_text
      else
        if fullMetadata.ng_xml.root.children.empty?
          fullMetadata.ng_xml = xml_text
        end
        # For EAD XML updates discard any children components in the XML
        # as NO hierarchy updates are supported, only MD
        xml_text = split_ead_xml(xml_text, desc_metadata_class)
        descMetadata.ng_xml = xml_text
      end

      true
    end

    # If this is EAD, put the full XML in fullMetadata and
    # return XML with the component's children removed
    # @param [Nokogiri::XML] xml_text the XML metadata for the object
    # @param [String] xml_type the type of object (DRI::Batch class)
    # @return [Nokogiri::XML] the modified XML document
    def split_ead_xml(xml_text, xml_type)
      if xml_text.is_a?(Nokogiri::XML::Document)
        xml = xml_text
      else
        xml = Nokogiri::XML xml_text
      end
      # Remove namespaces from XML - handle EAD XSD
      # (EAD data model is namespace-free)
      xml.remove_namespaces!

      if xml_type == 'DRI::Metadata::EncodedArchivalDescription'
        xml.xpath('/ead/archdesc/dsc/*').remove
      else
        # 1. dsc/c
        if !xml.xpath('/*/dsc/*').empty?
          xml.xpath('/*/dsc/*').remove
        else
          # 2. c/c or 3. c/c01/c02...
          # Xpath 1.0 => /*/*[starts-with(local-name(), 'c')]
          # Xpath 2.0 => /*/*[matches(local-name(), 'c[01-12]')]
          xml.xpath('/*/*[starts-with(local-name(), "c") and string-length(local-name()) <= 3]').remove
        end
      end

      xml
    end

    private

    # Called within synchronize_if__changed (around_save callback)
    # if descMetadata updated
    def update_full_metadata
      has_ns = fullMetadata.ng_xml.collect_namespaces['xmlns:ead'] == 'urn:isbn:1-931666-22-9'

      if has_ns
        temp_desc_md = descMetadata.ng_xml.clone
        temp_desc_md.root.add_namespace('ead', 'urn:isbn:1-931666-22-9')
        temp_desc_md.root.add_namespace('xlink', 'http://www.w3.org/1999/xlink')

        temp_desc_md.search('//*').each do |n|
          # all ns prefix from root node to every child in the XML
          n.namespace = temp_desc_md.root.namespace_definitions.find { |ns| ns.prefix == 'ead' }
          # dao @href attr is under xlink ns if using EAD XSD
          if n['href']
            n.attribute('href').namespace = temp_desc_md.root.namespace_definitions.find { |ns| ns.prefix == 'xlink' }
          end
        end
        updated_desc_md = temp_desc_md
      else
        updated_desc_md = descMetadata.ng_xml.clone
      end

      children_components = DRI::ModelSupport::EadSupport.get_ead_metadata_components(fullMetadata.ng_xml)

      # copy children components from un-synced fullMetadata
      # as descMetadata does not include them
      unless children_components.empty?
        children_components.each do |node|
          if has_ns
            results = updated_desc_md.xpath('//ead:dsc', { 'xmlns:ead' => 'urn:isbn:1-931666-22-9' })
            dsc = results.empty? ? nil : results.first
          else
            dsc = updated_desc_md.at('//dsc')
          end

          if dsc.nil?
            # directly nested under the parent's component
            updated_desc_md.root.add_child(node)
          else
            # grouped under dsc, if present
            dsc.add_child(node)
          end
        end
      end

      fullMetadata.ng_xml = updated_desc_md

      true
    end

    def synchronize_if_changed
      content_changed = false

      content_changed = descMetadata.changed? if descMetadata.synchronize_metadata_on_save == true

      if trigger_update
        # after descMetadata update and before save
        # synchronise fullMetadata with descMetadata
        update_full_metadata if content_changed
        self.trigger_update = false if descMetadata.is_a?(DRI::Metadata::EncodedArchivalDescription)
      end

      # Do the object save
      yield

      return unless content_changed && !new_record?

      if trigger_ingest
        # This is an EAD ingest, not MD update
        Sufia.queue.push(SynchronizeChildrenToMetadataJob.new(id))
      elsif trigger_update && descMetadata.is_a?(DRI::Metadata::EncodedArchivalDescriptionComponent)
        # ONLY for EncodedArchivalDescriptionComponent
        # descMetadata update, trigger parent fullMetadata sync
        Sufia.queue.push(UpdateParentMetadataJob.new(id))
        self.trigger_update = false
      end
    end
  end # class
end # module
