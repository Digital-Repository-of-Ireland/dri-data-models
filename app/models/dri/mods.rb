module DRI
  class Mods < DRI::Batch
    include DRI::ModelSupport::ModsSupport

    # MODS relationships
    belongs_to :preceding, :property=>:related_preceding, :class_name => "DRI::Mods"
    belongs_to :succeeding, :property=>:related_succeeding, :class_name => "DRI::Mods"
    belongs_to :original, :property=>:related_original, :class_name => "DRI::Mods"
    belongs_to :host, :property=>:related_host, :class_name => "DRI::Mods"
    has_many :constituents, :property=>:related_constituent, :class_name => "DRI::Mods"
    belongs_to :series, :property=>:related_series, :class_name => "DRI::Mods"
    belongs_to :version, :property=>:related_version, :class_name => "DRI::Mods"
    belongs_to :format, :property=>:related_format, :class_name => "DRI::Mods"
    belongs_to :referenced_by, :property=>:related_referenced_by, :class_name => "DRI::Mods"
    belongs_to :references, :property=>:related_reference, :class_name => "DRI::Mods"
    belongs_to :review, :property=>:related_review, :class_name => "DRI::Mods"

    # MODS record identifier, not multi-valued
    has_attributes :mods_id, datastream: :descMetadata, multiple: false
    has_attributes :identifier, datastream: :descMetadata, multiple: false
    has_attributes :doi, datastream: :descMetadata, multiple: false
    has_attributes :uri, datastream: :descMetadata, multiple: false
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
    has_attributes :date_captured, datastream: :descMetadata, multiple: true
    has_attributes :date_other, datastream: :descMetadata, multiple: true
    # TODO - Ask Marta, Physical Description - Optional in the guidelines
    #has_attributes :physical_description, datastream: :descMetadata, multiple: true

    has_attributes :name_coverage, datastream: :descMetadata, multiple: true
    # Geographical, temporal
    has_attributes :geographical_coverage, datastream: :descMetadata, multiple: true
    has_attributes :temporal_coverage, datastream: :descMetadata, multiple: true
    has_attributes :subject_date_start, datastream: :descMetadata, multiple: true
    has_attributes :subject_date_end, datastream: :descMetadata, multiple: true
    has_attributes :subject_temporal, datastream: :descMetadata, multiple: true

    # Roles
    has_attributes  *(DRI::Vocabulary::marcRelators.map { |s| s.prepend("role_").to_sym}), datastream: :descMetadata,
                    multiple: true

    # Relationships
    has_attributes  *(DRI::Vocabulary::modsRelationshipTypes.map { |s| s.prepend("related_items_ids_").to_sym}),
                    datastream: :descMetadata, multiple: true

    around_save :create_multiple_records

    # Initialize - mods collection | mods record
    def initialize(type, args = {})
      case type
        when :collection
          metadata_class = "DRI::Metadata::ModsCollection"
        else
          metadata_class = "DRI::Metadata::Mods"
      end
      args[:desc_metadata_class] = metadata_class

      super(args)
    end

    def attributes=(properties)
      super(properties)
    end

    def update_metadata xml_text
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

      return true
    end

    def roles= roles
      if (descMetadata.class == DRI::Metadata::Mods || descMetadata.class == DRI::Metadata::ModsCollection)
        descMetadata.roles = roles
      end
    end

    def split_xml xml_text
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
        return new_xml.to_xml
      end
      # This is an individual record, therefore return all XML
      return xml_text
    end

    def self.find_or_create(pid)
      begin
        DRI::Mods.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
        DRI::Mods.create({pid: pid})
      end
    end

    def add_mods_relationships(root_collection)
      add_mods_relationship(related_items_ids_preceding, :preceding, root_collection)
      add_mods_relationship(related_items_ids_succeeding, :succeeding, root_collection)
      add_mods_relationship(related_items_ids_original, :original, root_collection)
      add_mods_relationship(related_items_ids_host, :host, root_collection)
      add_mods_relationship(related_items_ids_constituent, :constituents, root_collection)
      add_mods_relationship(related_items_ids_series, :series, root_collection)
      add_mods_relationship(related_items_ids_otherVersion, :version, root_collection)
      add_mods_relationship(related_items_ids_otherFormat, :format, root_collection)
      add_mods_relationship(related_items_ids_references, :references, root_collection)
      add_mods_relationship(related_items_ids_isReferencedBy, :referenced_by, root_collection)
      add_mods_relationship(related_items_ids_reviewOf, :review, root_collection)
    end # end add_relationships

    def add_mods_relationship(rels_array, rels_name, root_collection)
      if rels_array.empty?
        return
      end

      rels_array.each do |item_id|
        # We need to index the mods element ID to be able to search in Solr and then retrieve the document by id
        solr_query = "mods_id_tesim:\"#{item_id.to_s}\" "+
            "AND #{Solrizer.solr_name('root_collection_id', :stored_searchable, type: :string)}:\"#{root_collection}\""
        mods_item = ActiveFedora::SolrService.query(solr_query, :defType => "edismax")

        if mods_item.empty?
          # TODO Item not found, do we pop this id from related_item_ids?
          rels_array.pop item_id
        else
          doc = SolrDocument.new(mods_item[0])
          # Cast the solr document to its corresponding Fedora object
          mods_obj = DRI::Mods.find(doc.id)

          self.send("#{rels_name}=", mods_obj) unless mods_obj == nil
        end
      end

      # Save object, if valid
      self.save if self.valid?
    end # end add_mods_relationship

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
            Sufia.queue.push(CreateModsRecordsJob.new(self.pid))
          rescue Exception => e
            logger.error(e.message)
          end
        end
      end # end if
    end # end create_multiple_records
  end # class
end # module