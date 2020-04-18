# DRI namespace
module DRI
  # Implementation of DRI EAD digital objects extending from DRI::Base
  module EncodedArchivalDescription
    extend ActiveSupport::Concern
    include DRI::ModelSupport::EadSupport

    # Specific EAD terms mapped
    # Identifier - for ead header maps to eadid; for components to unitid
    # (!) Important - change on identifier for components: repeatable
    delegate :identifier,:identifier=, to: :descMetadata
    delegate :identifier_id,:identifier_id=, to: :descMetadata
    delegate :repository_code,:repository_code=, to: :descMetadata
    delegate :country_code,:country_code=, to: :descMetadata

    # ISO Dates
    delegate :creation_date_idx, to: :descMetadata
    delegate :published_date_idx, to: :descMetadata
    delegate :temporal_coverage_idx, to: :descMetadata

    # Description properties
    delegate :desc_abstract, to: :descMetadata
    delegate :desc_biog_hist, to: :descMetadata
    delegate :desc_scope_content, to: :descMetadata
    delegate :desc_dao_desc, to: :descMetadata

    # Subjects
    delegate :name_subject,:name_subject=, to: :descMetadata
    delegate :persname_subject,:persname_subject=, to: :descMetadata
    delegate :corpname_subject,:corpname_subject=, to: :descMetadata
    delegate :famname_subject,:famname_subject=, to: :descMetadata
    delegate :geogname_subject,:geogname_subject=, to: :descMetadata

    # Types
    delegate :ead_level,:ead_level=, to: :descMetadata
    delegate :ead_level_other,:ead_level_other=, to: :descMetadata

    # Files, description
    delegate :dao_proxy, to: :descMetadata
    delegate :dao_href_proxy, to: :descMetadata
    delegate :dao_desc_proxy, to: :descMetadata

    # Coverage: name, geographical, location, temporal
    delegate :name_coverage, to: :descMetadata
    delegate :geographical_coverage, to: :descMetadata
    delegate :geogname_coverage_access, to: :descMetadata
    delegate :temporal_coverage, to: :descMetadata

    # Related Material
    # The <relatedmaterial> element is comparable to ISAD(G)
    # data element 3.5.3 and MARC field 544 with indicator 1
    delegate :related_material, to: :descMetadata

    # Alternative Form Available
    delegate :alternative_form, to: :descMetadata

    delegate :resource_type, to: :descMetadata

    delegate :geocode_point, to: :descMetadata
    delegate :geocode_box, to: :descMetadata
    delegate :geocode_logainm, to: :descMetadata
    delegate :format,:format=, to: :descMetadata

    delegate :published_date, to: :descMetadata
    delegate :creation_date, to: :descMetadata

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
      #updated_props.keys.each do |k|
      #  next if k.to_sym != :type

      #  updated_props[:resource_type] = updated_props[k]
      #  updated_props.delete(k)
      #  break
      #end

      #puts updated_props

      #modified_attributes = updated_props.select { |key, _value| !DRI::EncodedArchivalDescription.ead_dri_terms.include? key.to_sym }
      #super(modified_attributes)
      super(updated_props)

      term_attributes = updated_props.select { |key, _value| DRI::EncodedArchivalDescription.ead_dri_terms.include? key.to_sym }
      self.trigger_update = true unless term_attributes.empty?
      #update_attributes.each { |key, value| self.send("#{key}=", value) unless value.nil? }
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

    def identifier_id
      descMetadata.identifier_id.first
    end

    def repository_code
      descMetadata.repository_code.first
    end

    def country_code
      descMetadata.country_code.first
    end

    def desc_abstract
      descMetadata.desc_abstract
    end

    def ead_level
      descMetadata.ead_level
    end

    def ead_level_other
      descMetadata.ead_level_other
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
      descMetadata.resource_type = type
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
        solr_doc.merge!(Solrizer.solr_name('is_first_sibling', :stored_searchable) => '1')
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
        file_type_display.push ead_level.first.strip.capitalize
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
        object_types.push(curr_category.split.map(&:capitalize) * ' ') unless curr_category.blank?
      end

      if object_types.empty?
        case descMetadata
        when DRI::Metadata::EncodedArchivalDescriptionComponent
          object_types.push('Collection') if descMetadata.collection?
          if ead_level.include? 'otherlevel'
            object_types.push(ead_level_other.split.first.map(&:capitalize) * ' ')
          else
            object_types.push(ead_level.split.first.map(&:capitalize) * ' ')
          end
        when DRI::Metadata::EncodedArchivalDescription
          object_types.push('Collection')
        end
      end

      object_types.push('Unknown') if object_types.count < 1

      solr_doc.merge!(Solrizer.solr_name('object_type', :facetable) => object_types)
      solr_doc.merge!(Solrizer.solr_name('object_type', :displayable) => object_types)

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
        xml_text = split_ead_xml(xml_text, descMetadata.class.to_s)

        descMetadata.ng_xml = xml_text
      else
        if fullMetadata.ng_xml.root.children.empty?
          fullMetadata.ng_xml = xml_text
        end
        # For EAD XML updates discard any children components in the XML
        # as NO hierarchy updates are supported, only MD
        xml_text = split_ead_xml(xml_text, descMetadata.class.to_s)
        descMetadata.ng_xml = xml_text
      end

      true
    end

    # If this is EAD, put the full XML in fullMetadata and
    # return XML with the component's children removed
    # @param [Nokogiri::XML] xml_text the XML metadata for the object
    # @param [String] xml_type the type of object (DRI::Base class)
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

      children_components = DRI::ModelSupport::EadSupport.ead_metadata_components(fullMetadata.ng_xml)

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

          if dsc
            # grouped under dsc, if present
            dsc.add_child(node)
          else
             # directly nested under the parent's component
            updated_desc_md.root.add_child(node)
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
        DRI.queue.push(SynchronizeChildrenToMetadataJob.new(id))
      elsif trigger_update && descMetadata.is_a?(DRI::Metadata::EncodedArchivalDescriptionComponent)
        # ONLY for EncodedArchivalDescriptionComponent
        # descMetadata update, trigger parent fullMetadata sync
        DRI.queue.push(UpdateParentMetadataJob.new(id))
        self.trigger_update = false
      end
    end

    def method_missing(method, *args)
      if self.class.terminology.has_term?(*OM.destringify(term_pointer))
        descMetadata.send(method, *args)
      else
        super
      end
    end
  end # class
end # module
