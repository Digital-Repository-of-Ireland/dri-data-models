module DRI
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
    # The <relatedmaterial> element is comparable to ISAD(G) data element 3.5.3 and MARC field 544 with indicator 1
    property :related_material, delegate_to: 'descMetadata', multiple: true

    # Alternative Form Available
    property :alternative_form, delegate_to: 'descMetadata', multiple: true

    property :type, delegate_to: 'descMetadata', multiple: true

    property :geocode_point, delegate_to: 'descMetadata', multiple: true
    property :geocode_box, delegate_to: 'descMetadata', multiple: true
    property :geocode_logainm, delegate_to: 'descMetadata', multiple: true

    around_save :synchronize_if_changed

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

    def self.find_or_create(pid)
      begin
        DRI::EncodedArchivalDescription.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
        DRI::EncodedArchivalDescription.create({id: pid})
      end
    end

    def self.ead_dri_terms
      return [:title, :creator, :contributor, :desc_scope_content, :desc_abstract, :desc_biog_hist,
              :creation_date, :published_date, :name_coverage, :temporal_coverage, :rights, :subject, :name_subject, :persname_subject,
              :corpname_subject, :geogname_subject, :geogname_coverage_access, :famname_subject, :publisher, :type,
              :related_material, :alternative_form, :language]
    end

    def attributes=(properties)
      modified_attributes = properties.select {|key, value| !DRI::EncodedArchivalDescription.ead_dri_terms.include? key.to_sym }
      super(modified_attributes)

      update_attributes = properties.select {|key, value| DRI::EncodedArchivalDescription.ead_dri_terms.include? key.to_sym }

      update_attributes.each { |key, value| self.send("#{key.to_s}=", value) unless value.nil? }
    end

    def editable_attributes
      editable_attrs = Hash.new
      DRI::EncodedArchivalDescription.ead_dri_terms.each do |attr|
        editable_attrs[attr] = self.send("#{attr.to_s}")
      end

      editable_attrs
    end

    def get_hash_attributes
      self.descMetadata.retrieve_terms_hash
    end

    def creator=(creators)
      self.descMetadata.add_creator(creators)
    end

    def contributor=(contributors)
      self.descMetadata.add_contributor(contributors)
    end

    def desc_scope_content=(descriptions)
      self.descMetadata.add_desc_scope_content(descriptions)
    end

    def desc_abstract=(descriptions)
      self.descMetadata.add_desc_abstract(descriptions)
    end

    def desc_biog_hist=(descriptions)
      self.descMetadata.add_desc_biog_hist(descriptions)
    end

    def creation_date=(dates)
      self.descMetadata.add_creation_date(dates) unless dates.empty?
    end

    def published_date=(dates)
      self.descMetadata.add_published_date(dates) unless dates.empty?
    end

    def temporal_coverage=(dates)
      self.descMetadata.add_temporal_coverage(dates) unless dates.empty?
    end

    def name_coverage=(people)
      self.descMetadata.add_name_coverage(people) unless people.empty?
    end

    def alternative_form=(materials)
      self.descMetadata.add_alternative_form(materials) unless materials.empty?
    end

    def related_material=(materials)
      self.descMetadata.add_related_material(materials) unless materials.empty?
    end

    def geogname_coverage_access=(locations)
      self.descMetadata.add_geogname_coverage_access(locations) unless locations.empty?
    end

    def language=(languages)
      self.descMetadata.add_language(languages) unless languages.empty?
    end

    # Override from collection.rb adding EAD-specific solr additions
    def collections_to_solr(solr_doc=Hash.new)
      solr_doc = super(solr_doc)
      if descMetadata.class == DRI::Metadata::EncodedArchivalDescriptionComponent && previous_sibling == nil
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('is_first_sibling', :stored_searchable) => '1')
      end
      solr_doc
    end

    # Override from files.rb adding EAD-specific solr additions
    def file_metadata_to_solr(solr_doc=Hash.new)
      solr_doc = super(solr_doc)

      file_type = []
      file_type_display = []

      if is_collection?
        file_type.push('collection')

        if !is_root_collection? && !ead_level.blank?
          file_type_display.push ead_level.strip.capitalize
        else
          file_type_display.push('Collection')
        end
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
            if descMetadata.collection?
              object_types.push('Collection')
            end
            if ead_level.include? 'otherlevel'
              object_types.push ead_level_other.split.map(&:capitalize)*' '
            else
              object_types.push ead_level.split.map(&:capitalize)*' '
            end
        when DRI::Metadata::EncodedArchivalDescription
          object_types.push('Collection')
        end
      end

      if object_types.count < 1
        object_types.push('Unknown')
      end
      solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('object_type', :facetable) => object_types)
      solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('object_type', :displayable) => object_types)

      solr_doc
    end

    # Updates the XML metadata for the object's descMetadata datastream
    # @param [String, File] xml_text String or file containing xml metadata to be updated
    # @param [Boolean] ingest true if ingest operation; false if metadata update operation
    # @return [Boolean] true if xml updated successfully; false otherwise
    def update_metadata(xml_text, ingest=true)
      # Differentiate between ingest and individual object update
      ingest ? self.trigger_ingest=(true) : self.trigger_update=(true)

      if xml_text.is_a?(File)
        xml_text = xml_text.read
      end

      fullMetadata.ng_xml = xml_text
      xml_text = split_ead_xml(xml_text, desc_metadata_class)

      descMetadata.ng_xml = xml_text

      true
    end

    # If this is EAD, put the full XML in fullMetadata and
    # return XML with the component's children removed
    def split_ead_xml(xml_text, xml_type)
      if xml_text.is_a?(Nokogiri::XML::Document)
        xml = xml_text
      else
        xml = Nokogiri::XML xml_text
      end
      # Remove namespaces from XML - handle EAD XSD (EAD data model is namespace-free)
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

    def synchronize_if_changed
      content_changed = false

      if self.descMetadata.synchronize_metadata_on_save == true && self.trigger_ingest
        content_changed = self.descMetadata.changed?
      end

      # Do the object save
      yield

      if content_changed && !new_record?
        Sufia.queue.push(SynchronizeChildrenToMetadataJob.new(self.id))
      end
    end

  end # class
end # module
