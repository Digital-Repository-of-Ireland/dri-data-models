module DRI
  class Mods < DRI::Batch
    include DRI::ModelSupport::ModsSupport

    # MODS relationships
    belongs_to :preceding, :property=>:related_preceding, :class_name => "DRI::Mods"
    belongs_to :succeeding, :property=>:related_succeeding, :class_name => "DRI::Mods"
    belongs_to :original, :property=>:related_original, :class_name => "DRI::Mods"
    belongs_to :host, :property=>:related_host, :class_name => "DRI::Mods"
    # Constituents is managed through the host relationship. This automatically adds a constituent
    # whenever a host relationship is added
    has_many :constituents, :property=>:related_host, :class_name => "DRI::Mods"
    belongs_to :series, :property=>:related_series, :class_name => "DRI::Mods"
    has_many :version, :property=>:related_version, :class_name => "DRI::Mods"
    has_many :format, :property=>:related_format, :class_name => "DRI::Mods"
    has_many :referenced_by, :property=>:related_referenced_by, :class_name => "DRI::Mods"
    has_many :references, :property=>:related_reference, :class_name => "DRI::Mods"
    has_many :review, :property=>:related_review, :class_name => "DRI::Mods"

    # MODS record identifier mods:identifier[@type='local'], not multi-valued
    has_attributes :mods_id_local, datastream: :descMetadata, multiple: false
    # MODS rest of identifiers are repeatable
    has_attributes :identifier, datastream: :descMetadata, multiple: true
    has_attributes :id_doi, datastream: :descMetadata, multiple: true
    has_attributes :id_uri, datastream: :descMetadata, multiple: true
    # Collection attribute
    has_attributes :mods_type_collection, datastream: :descMetadata, multiple: false
    # Title
    has_attributes :subtitle, datastream: :descMetadata, multiple: true
    # Description
    has_attributes :abstract, datastream: :descMetadata, multiple: true
    has_attributes :toc, datastream: :descMetadata, multiple: true
    has_attributes :note_mods_type, datastream: :descMetadata, multiple: true
    has_attributes :note_mods_no_type, datastream: :descMetadata, multiple: true
    # Source
    has_attributes :source, datastream: :descMetadata, multiple: true
    # Dates
    has_attributes :date, datastream: :descMetadata, multiple: true
    has_attributes :date_other, datastream: :descMetadata, multiple: true
    has_attributes :date_other_start, datastream: :descMetadata, multiple: true
    has_attributes :date_other_end, datastream: :descMetadata, multiple: true
    has_attributes :captured_date, datastream: :descMetadata, multiple: true
    has_attributes :captured_date_start, datastream: :descMetadata, multiple: true
    has_attributes :captured_date_end, datastream: :descMetadata, multiple: true
    has_attributes :issued_date_start, datastream: :descMetadata, multiple: true
    has_attributes :issued_date_end, datastream: :descMetadata, multiple: true
    has_attributes :creation_date_start, datastream: :descMetadata, multiple: true
    has_attributes :creation_date_end, datastream: :descMetadata, multiple: true

    has_attributes :name_coverage, datastream: :descMetadata, multiple: true
    # Geographical, temporal
    has_attributes :geographical_coverage, datastream: :descMetadata, multiple: true
    has_attributes :temporal_coverage, datastream: :descMetadata, multiple: true
    has_attributes :subject_date_start, datastream: :descMetadata, multiple: true
    has_attributes :subject_date_end, datastream: :descMetadata, multiple: true

    # External relationships (contain a URI to resources external to DRI)
    has_attributes *(DRI::Vocabulary::modsRelationshipTypes.map { |s| s.prepend("ext_related_items_ids_").to_sym}),
                   datastream: :descMetadata, multiple: true
    # Internal Relationships
    has_attributes  *(DRI::Vocabulary::modsRelationshipTypes.map { |s| s.prepend("related_items_ids_").to_sym}),
                    datastream: :descMetadata, multiple: true

    # Roles
    has_attributes  *(DRI::Vocabulary::marcRelators.map { |s| s.prepend("role_").to_sym}), datastream: :descMetadata,
                    multiple: true

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
      oai_dc_xml = DRI::Utils.apply_xslt_transformation('xslt/mods2oai_dc.xsl', object)
      self.datastreams['DC'].content = oai_dc_xml.to_s

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

    # Iterate over every collection's object and process relationships
    #
    def process_collection_relationships
      if self.is_root_collection?
        # Get all the collection's objects
        # We need to index the mods element ID to be able to search in Solr and then retrieve the document by id
        solr_query = "#{Solrizer.solr_name('root_collection_id', :stored_searchable, type: :string)}:\"#{self.id.to_s}\""

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
              logger.error(e.message)
            end
          end
        end
      else
        # Only process the object's relationships
        Sufia.queue.push(CreateModsRelationshipsJob.new(self.id))
        # logger.error("The object #{self.pid} is not a collection container.")
      end
    end # end add_relationships

    def process_relationships()
      add_dm_relationship(related_items_ids_preceding, :preceding)
      add_dm_relationship(related_items_ids_succeeding, :succeeding)
      add_dm_relationship(related_items_ids_original, :original)
      add_dm_relationship(related_items_ids_host, :host)
      add_dm_relationship(related_items_ids_constituent, :constituents)
      add_dm_relationship(related_items_ids_series, :series)
      add_dm_relationship(related_items_ids_otherVersion, :version)
      add_dm_relationship(related_items_ids_otherFormat, :format)
      add_dm_relationship(related_items_ids_references, :references)
      add_dm_relationship(related_items_ids_isReferencedBy, :referenced_by)
      add_dm_relationship(related_items_ids_reviewOf, :review)
    end

    # Process a specific mods relationship for the object
    # @return true if successful; false otherwise
    #
    def add_dm_relationship(rels_array, rels_name)
      if rels_array.empty?
        return true
      end

      # Get Root collection
      solr_query = "id:\"#{id.to_s}\""
      # The query service returns back a set of Solr Documents, therefore need to be casted later on
      solr_docs = ActiveFedora::SolrService.query(solr_query, :defType => "edismax")

      if (solr_docs == nil || solr_docs == [])
        logger.error("Solr document for object with PID #{self.pid} not found in Solr")
        return false
      end

      doc = SolrDocument.new(solr_docs[0])
      root_collection = doc[Solrizer.solr_name('root_collection_id', :stored_searchable, type: :string)]

      if (root_collection == nil)
        logger.error("Root collection ID for object with PID #{self.pid} not found in Solr")
        return false
      end

      rels_array.each do |item_id|
        # We need to index the mods element ID to be able to search in Solr and then retrieve the document by id
        solr_query = "mods_id_local_tesim:\"#{item_id.to_s}\" "+
            "AND #{Solrizer.solr_name('root_collection_id', :stored_searchable, type: :string)}:\"#{root_collection.to_s}\""
        mods_item = ActiveFedora::SolrService.query(solr_query, :defType => "edismax")

        if mods_item.empty?
          logger.error("Relationship target object #{item_id} not found in Solr for object #{self.id}")
          return false
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
              self.governing_collection = mods_obj
            else
              if self.send("#{rels_name}").respond_to?("push")
                self.send("#{rels_name}").push mods_obj
              else
                self.send("#{rels_name}=", mods_obj)
              end
            end
          end
        end
      end

      # Save object, if valid
      if self.valid?
        self.save
        return true
      else
        return false
      end
    end # end add_mods_relationship

    def get_relationships_names
      return {:preceding => "Is Preceded By",
              :succeeding => "Is Succeeded By",
              :original => "Has Original",
              :host => "Host",
              :constituents => "Constituents",
              :series => "Has Series",
              :version => "Is Version Of",
              :format => "Is Format Of",
              :referenced_by => "Is Referenced By",
              :references => "References",
              :review => "Is Review Of"
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
  end # Class Mods
end # Module DRI
