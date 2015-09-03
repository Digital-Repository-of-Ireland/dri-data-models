module DRI
  class Mods < DRI::Batch
    include DRI::ModelSupport::ModsSupport

    contains "descMetadata", class_name: "DRI::Metadata::Mods"

    # MODS relationships
    # To express the bi-directionality of the sequencing relationships
    # belongs_to means that the foreign key is in the table for this class.
    # So belongs_to can ONLY go in the class that holds the foreign key
    # has_one means that there is a foreign key in another table that references this class.
    # So has_one can ONLY go in a class that is referenced by a column in another table.
    # ActiveFedora does not implement has_one. They treat it as a special case of has_many (1-to-1 association)
    # so we need to validate that there is only one!!
    #belongs_to :preceding, predicate: DRI::RDFVocabularies::ModsRelsVocabulary.relatedPreceding, class_name: "DRI::Mods"
    #has_many :succeeding, predicate: DRI::RDFVocabularies::ModsRelsVocabulary.relatedPreceding, class_name: "DRI::Mods", as: :preceding

    #belongs_to :original, predicate: DRI::RDFVocabularies::ModsRelsVocabulary.relatedOriginal, class_name: "DRI::Mods"

    #belongs_to :host, predicate: DRI::RDFVocabularies::ModsRelsVocabulary.relatedHost, class_name: "DRI::Mods"
    # Constituents is managed through the host relationship. This automatically adds a constituent
    # whenever a host relationship is added
    #has_many :constituents, predicate: DRI::RDFVocabularies::ModsRelsVocabulary.relatedHost, class_name: "DRI::Mods", as: :host

    #belongs_to :series, predicate: DRI::RDFVocabularies::ModsRelsVocabulary.relatedSeries, class_name: "DRI::Mods"
    #has_and_belongs_to_many :other_version, predicate: DRI::RDFVocabularies::ModsRelsVocabulary.relatedVersion, class_name: "DRI::Mods"
    #has_and_belongs_to_many :other_format, predicate: DRI::RDFVocabularies::ModsRelsVocabulary.relatedFormat, class_name: "DRI::Mods"
    #has_and_belongs_to_many :referenced_by, predicate: DRI::RDFVocabularies::ModsRelsVocabulary.relatedReferencedBy, class_name: "DRI::Mods"
    #has_and_belongs_to_many :references, predicate: DRI::RDFVocabularies::ModsRelsVocabulary.relatedReference, class_name: "DRI::Mods"
    #has_and_belongs_to_many :review, predicate: DRI::RDFVocabularies::ModsRelsVocabulary.relatedReview, class_name: "DRI::Mods"

    # MODS record identifier mods:identifier[@type='local'], not multi-valued
    property :mods_id_local, delegate_to: 'descMetadata', multiple: false
    # MODS record asset identifier used to sort pages/sequenced items
    property :id_asset, delegate_to: 'descMetadata', multiple: false
    # MODS rest of identifiers are repeatable
    property :identifier, delegate_to: 'descMetadata', multiple: true
    property :id_doi, delegate_to: 'descMetadata', multiple: true
    property :id_uri, delegate_to: 'descMetadata', multiple: true
    # Collection attribute
    property :mods_type_collection, delegate_to: 'descMetadata', multiple: false
    # Title
    property :subtitle, delegate_to: 'descMetadata', multiple: true
    # Description
    property :abstract, delegate_to: 'descMetadata', multiple: true
    property :toc, delegate_to: 'descMetadata', multiple: true
    property :note_mods_type, delegate_to: 'descMetadata', multiple: true
    property :note_mods_no_type, delegate_to: 'descMetadata', multiple: true
    # Source
    property :source, delegate_to: 'descMetadata', multiple: true
    # Dates
    property :date, delegate_to: 'descMetadata', multiple: true
    property :date_other, delegate_to: 'descMetadata', multiple: true
    property :date_other_start, delegate_to: 'descMetadata', multiple: true
    property :date_other_end, delegate_to: 'descMetadata', multiple: true
    property :captured_date, delegate_to: 'descMetadata', multiple: true
    property :captured_date_start, delegate_to: 'descMetadata', multiple: true
    property :captured_date_end, delegate_to: 'descMetadata', multiple: true
    property :issued_date_start, delegate_to: 'descMetadata', multiple: true
    property :issued_date_end, delegate_to: 'descMetadata', multiple: true
    property :creation_date_start, delegate_to: 'descMetadata', multiple: true
    property :creation_date_end, delegate_to: 'descMetadata', multiple: true

    property :name_coverage, delegate_to: 'descMetadata', multiple: true
    # Geographical, temporal
    property :geographical_coverage, delegate_to: 'descMetadata', multiple: true
    property :temporal_coverage, delegate_to: 'descMetadata', multiple: true
    property :subject_date_start, delegate_to: 'descMetadata', multiple: true
    property :subject_date_end, delegate_to: 'descMetadata', multiple: true

    # External relationships (contain a URI to resources external to DRI)
    has_attributes *(DRI::Vocabulary::modsRelationshipTypes.map { |s| s.prepend("ext_related_items_ids_").to_sym}),
                   datastream: :descMetadata, multiple: true
    # Internal Relationships
    has_attributes  *(DRI::Vocabulary::modsRelationshipTypes.map { |s| s.prepend("related_items_ids_").to_sym}),
                    datastream: :descMetadata, multiple: true

    # Roles
    has_attributes  *(DRI::Vocabulary::marcRelators.map { |s| s.prepend("role_").to_sym}), datastream: :descMetadata,
                    multiple: true

    property :type, delegate_to: 'descMetadata', multiple: true

    # TODO Disabled for now
    #around_save :create_multiple_records

    # Initialize - mods record
    def initialize(args = {})
      args[:desc_metadata_class] = "DRI::Metadata::Mods"
      super(args)
    end

    def attributes=(properties)
      super(properties)
    end

    def update_metadata(xml_text)
      self.trigger_update=(true)
      if (xml_text.is_a? File)
        xml_text = xml_text.read
      end

      if (xml_text.is_a? Nokogiri::XML::Document)
        xml = xml_text
      else
        xml = Nokogiri::XML xml_text
      end

      xml_without_blanks = Nokogiri::XML.parse(xml.to_xml) do |config|
        config.noblanks
      end

      fullMetadata.ng_xml = xml_without_blanks
      # Important, we remove all the namespaces for descriptiveMetadata
      # object = split_xml xml_without_blanks.remove_namespaces!
      object = split_xml xml_without_blanks
      descMetadata.ng_xml = object

      # Apply XSLT MODS 2 OAI_DC, and store it in Fedora's DC datastream
      # oai_dc_xml = DRI::Utils.apply_xslt_transformation('xslt/mods2oai_dc.xsl', object)
      # FIXME F4 deprecated below
      # self.datastreams['DC'].content = oai_dc_xml.to_s

      return true
    end

    def roles=(roles)
      if (descMetadata.class == DRI::Metadata::Mods || descMetadata.class == DRI::Metadata::ModsCollection)
        descMetadata.roles = roles
      end
    end

    def split_xml(xml_text)
      unless xml_text.search("/mods:modsCollection").empty?
        collection = xml_text.search("/mods:modsCollection")
        mods_records = collection.children
        # Return only the first MODS record; the rest will be created in resque jobs
        record = mods_records[0]

        # Need to add the namespace declarations to the mods:mods root element
        # Otherwise the terminology (xpath) won't find the elements
        new_xml = Nokogiri::XML::Builder.new do |xml|
          xml.mods({"xmlns:mods"=>"http://www.loc.gov/mods/v3"}, record.namespaces) {
            xml.parent.namespace = xml.parent.namespace_definitions.find{|ns| ns.href}
            xml << record.children.to_xml
          }
        end

        # Return the first record
        return Nokogiri::XML(new_xml.to_xml)
      end
      # This is an individual record, therefore return all XML
      return xml_text
    end

    def self.find_or_create(pid)
      begin
        DRI::Mods.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
        DRI::Mods.create({id: pid})
      end
    end

=begin
    # Iterate over every collection's object and process relationships
    # Recursive: if object is collection then process collection relationships
    # Once all the current object's children's rels have been process then process the current rels
    def process_collection_relationships
      if self.is_collection?
        # Get all the collection's objects
        # We need to index the mods element ID to be able to search in Solr and then retrieve the document by id
        solr_query = "#{ActiveFedora::SolrQueryBuilder.solr_name('collection_id', :stored_searchable, type: :string)}:\"#{self.id.to_s}\""

        # collection_objects_docs = ActiveFedora::SolrService.query(solr_query, :defType => "edismax")
        query = Solr::Query.new(solr_query)
        while (query.has_more?)
          collection_objects_docs = query.pop
          collection_objects_docs.each do |obj_doc|
            doc = SolrDocument.new(obj_doc)
            object = DRI::Mods.find(doc.id)
            begin
              Sufia.queue.push(CreateModsRelationshipsJob.new(object.id))
            rescue Exception => e
              Rails.logger.error(e.message)
            end
          end
        end
        # Once we've processed all the children, then process this object
        process_relationships()
      else
        # Only process the object's relationships
        process_relationships()
        # Rails.logger.error("The object #{self.pid} is not a collection container.")
      end
    end # end add_relationships

    def process_relationships()
      #add_dm_relationship(related_items_ids_preceding, :preceding)
      ##add_dm_relationship(related_items_ids_succeeding, :succeeding)
      #add_dm_relationship(related_items_ids_original, :original)
      #add_dm_relationship(related_items_ids_host, :host)
      ##add_dm_relationship(related_items_ids_constituent, :constituents)
      #add_dm_relationship(related_items_ids_series, :series)
      #add_dm_relationship(related_items_ids_otherVersion, :other_version)
      #add_dm_relationship(related_items_ids_otherFormat, :other_format)
      #add_dm_relationship(related_items_ids_references, :references)
      #add_dm_relationship(related_items_ids_isReferencedBy, :referenced_by)
      #add_dm_relationship(related_items_ids_reviewOf, :review)

      # After processing all the relationships for the object, save
      #self.save if self.valid?
    end
=end

    def self.relationships
      return {preceding: {label: "Preceding", field: "related_items_ids_preceding"},
              succeeding: {label: "Succeeding", field: "related_items_ids_succeeding"},
              original: {label: "Has Original", field: "related_items_ids_original"},
              host: {label: "Is Part Of", field: "related_items_ids_host"},
              constituents: {label: "Has Parts", field: "related_items_ids_constituent"},
              series: {label: "Has Series", field: "related_items_ids_series"},
              other_version: {label: "Is Version Of", field: "related_items_ids_otherVersion"},
              other_format: {label: "Is Format Of", field: "related_items_ids_otherFormat"},
              referenced_by: {label: "Is Referenced By", field: "related_items_ids_isReferencedBy"},
              references: {label: "References", field: "related_items_ids_references"},
              review: {label: "Is Review Of", field: "related_items_ids_reviewOf"}
      }
    end

    def self.solr_relationships_field
      ActiveFedora::SolrQueryBuilder.solr_name('mods_id_local', :stored_searchable, type: :string)
    end

    def get_relationships_records
      return {:preceding => retrieve_relation_records(related_items_ids_preceding, self.class.solr_relationships_field),
              :succeeding => retrieve_relation_records(related_items_ids_succeeding, self.class.solr_relationships_field),
              :original => retrieve_relation_records(related_items_ids_original, self.class.solr_relationships_field),
              :host => retrieve_relation_records(related_items_ids_host, self.class.solr_relationships_field),
              :constituents => retrieve_relation_records(related_items_ids_constituent, self.class.solr_relationships_field),
              :series => retrieve_relation_records(related_items_ids_series, self.class.solr_relationships_field),
              :other_version => retrieve_relation_records(related_items_ids_otherVersion, self.class.solr_relationships_field),
              :other_format => retrieve_relation_records(related_items_ids_otherFormat, self.class.solr_relationships_field),
              :referenced_by => retrieve_relation_records(related_items_ids_isReferencedBy, self.class.solr_relationships_field),
              :references => retrieve_relation_records(related_items_ids_references, self.class.solr_relationships_field),
              :review => retrieve_relation_records(related_items_ids_reviewOf, self.class.solr_relationships_field)
      }
    end

    def create_multiple_records
      yield # Do save the object

      if (self.trigger_update)
        # Check whether there are namespaces
        #if self.fullMetadata.ng_xml.namespaces.values.include?("http://www.loc.gov/mods/v3")
        # Get the prefix used in the XML for MODS
        #  ns_array = self.fullMetadata.ng_xml.namespaces.select{ |key, hash| hash == "http://www.loc.gov/mods/v3"}.first
        #  prefix = ns_array.first.to_s.dup
        #  prefix.slice! "xmlns:"

        #  query = self.fullMetadata.ng_xml.search("//#{prefix}:mods")
        #else
        query = self.fullMetadata.ng_xml.search("//mods:mods")
        #end

        if !new_record? && query.count > 1
          begin
            Sufia.queue.push(CreateModsRecordsJob.new(self.id))
          rescue Exception => e
            Logger.error(e.message)
          end
        end
      end # end if
    end # end create_multiple_records

    private

    # Process a specific mods relationship for the object
    #
    def add_dm_relationship(rels_array, rels_name)
      # Reset previous relationships
      if self.send("#{rels_name}").respond_to?("push")
        self.send("#{rels_name}").clear
      else
        self.association(rels_name.to_sym).replace(nil)
      end

      if rels_array.empty?
        return
      end

      # Get Root collection
      solr_query = "id:\"#{id.to_s}\""
      # The query service returns back a set of Solr Documents, therefore need to be casted later on
      solr_docs = ActiveFedora::SolrService.query(solr_query, :defType => "edismax")

      if (solr_docs == nil || solr_docs == [])
        Rails.logger.error("Solr document for object with PID #{self.pid} not found in Solr")
        return
      end

      doc = SolrDocument.new(solr_docs[0])
      root_collection = doc[ActiveFedora::SolrQueryBuilder.solr_name('root_collection_id', :stored_searchable, type: :string)]

      if (root_collection == nil)
        logger.error("Root collection ID for object with PID #{self.pid} not found in Solr")
        return
      end

      rels_array.each do |item_id|
        # FIXME Revise these two queries
        # We need to index the mods element ID to be able to search in Solr and then retrieve the document by id
        solr_query = "#{ActiveFedora::SolrQueryBuilder.solr_name('mods_id_local', :stored_searchable, type: :string)}:\"#{item_id.to_s}\""
        solr_query << " AND #{ActiveFedora::SolrQueryBuilder.solr_name('root_collection_id', :stored_searchable, type: :string)}:\"#{root_collection.first.to_s}\""
        mods_item = ActiveFedora::SolrService.query(solr_query, :defType => "edismax")

        if mods_item.empty?
          Rails.logger.error("Relationship target object #{item_id} not found in Solr for object #{self.id}")
        else
          doc = SolrDocument.new(mods_item[0])
          # Cast the solr document to its corresponding Fedora object
          mods_obj = DRI::Mods.find(doc.id)
          unless mods_obj == nil
            if (rels_name.equal?(:constituents))
              mods_obj.send("#{:host}=", self)
              mods_obj.save if mods_obj.valid?
            elsif rels_name.equal?(:host)
              self.send("#{rels_name}=", mods_obj)
              #self.association(:governing_collection).replace(mods_obj)
            else
              if self.send("#{rels_name}").respond_to?("push")
                self.send("#{rels_name}").push mods_obj
              else
                self.send("#{rels_name}=", mods_obj)
              end
            end

            # Save object, if valid
            #self.save if self.valid?
          end
        end
      end
    end # end add_mods_relationship
  end # Class Mods
end # Module DRI
