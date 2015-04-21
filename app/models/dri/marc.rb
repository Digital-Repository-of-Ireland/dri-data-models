module DRI
class Marc < DRI::Batch 

  include DRI::ModelSupport::MarcSupport

  has_attributes :leader, datastream: :descMetadata, multiple: false
  has_attributes :controlfield, :controlfield_tag, datastream: :descMetadata, multiple: true
  has_attributes :datafield, :datafield_tag, :datafield_ind1, :datafield_ind2, datastream: :descMetadata, multiple: true
  has_attributes :marc_id, datastream: :descMetadata, multiple: false

  # MARC Relationships, mapped from QDC predicate properties
  # 787: Other Relationship Entry; Mapped to DC: relation
  has_many :related, :property=>:dcterms_relation, :class_name => "DRI::Marc"
  # 775: Other Edition Entry; Mapped to QDC: isVersionOf
  has_many :version, :property=>:dcterms_is_version_of, :class_name => "DRI::Marc"
  # 776: Additional Physical Form Entry; Mapped to QDC: isFormatOf
  has_many :format_of, :property=>:dcterms_is_format_of, :class_name => "DRI::Marc"

  # Mapped attributes for getting relational information from metadata
  # Internal Relationships
  has_attributes  :relation_ids_isVersionOf, datastream: :descMetadata, multiple: true
  has_attributes  :relation_ids_isFormatOf, datastream: :descMetadata, multiple: true
  has_attributes  :relation_ids_relation, datastream: :descMetadata, multiple: true

  has_attributes :related_material, datastream: :descMetadata, multiple: true
  has_attributes :alternative_form, datastream: :descMetadata, multiple: true

  around_save :create_multiple_records

  def initialize(params = {})
    params[:desc_metadata_class] = "DRI::Metadata::Marc"
    super(params)
  end

  def type
    descMetadata.type
  end

  def update_metadata xml_text
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
    object = split_xml xml_without_blanks.remove_namespaces!
    descMetadata.ng_xml = object

    return true
  end

  def split_xml xml_text
    collection = xml_text.search("//collection")
    records = collection.children
    record = records[0]

    collection[0].children.remove
    collection[0].add_child(record)
    
    return collection[0].to_xml
  end

  def attributes=(properties)
    controlfields = properties.delete('controlfield')
    datafields = properties.delete('datafield')
    super(properties)

    self.descMetadata.add_controlfields(controlfields) unless controlfields.nil?
    self.descMetadata.add_datafields(datafields) unless datafields.nil?
  end

  # Iterate over every collection's object and process relationships
  #
  def process_collection_relationships
    if self.is_collection?
      # Get all the collection's objects
      # We need to index the mods element ID to be able to search in Solr and then retrieve the document by id
      solr_query = "#{Solrizer.solr_name('collection_id', :stored_searchable, type: :string)}:\"#{self.pid.to_s}\""

      query = Solr::Query.new(solr_query)
      while (query.has_more?)
        collection_objects_docs = query.pop
        collection_objects_docs.each do |obj_doc|
          doc = SolrDocument.new(obj_doc)
          object = DRI::Mods.find(doc.id)
          begin
            Sufia.queue.push(CreateMarcRelationshipsJob.new(object.pid))
          rescue Exception => e
            Rails.logger.error(e.message)
          end
        end
        # Once we've processed all the children, then process this object
        process_relationships()
      end
    else
      # Only process the object's relationships
      process_relationships()
      # Rails.logger.error("The object #{self.pid} is not a collection container.")
    end
  end # end add_relationships

  def process_relationships()
    add_dm_relationship(relation_ids_relation, :related)
    add_dm_relationship(relation_ids_isVersionOf, :version)
    add_dm_relationship(relation_ids_isFormatOf, :format_of)
  end

  # Process a specific qdc relationship for the object
  #
  def add_dm_relationship(rels_array, rels_name)
    if rels_array.empty?
      return
    end

    # Get Root collection of current object.
    # This is to restrict relationship processing only within the given collection
    solr_query = "id:\"#{pid.to_s}\""
    # The query service returns back a set of Solr Documents, therefore need to be casted later on
    solr_docs = ActiveFedora::SolrService.query(solr_query, :defType => "edismax")

    if (solr_docs == nil || solr_docs == [])
      Rails.logger.error("Solr document for object with PID #{self.pid} not found in Solr")
      return
    end

    doc = SolrDocument.new(solr_docs[0])
    root_collection = doc[Solrizer.solr_name('root_collection_id', :stored_searchable, type: :string)]

    if (root_collection == nil)
      Rails.logger.error("Root collection ID for object with PID #{self.pid} not found in Solr")
      return
    end

    rels_array.each do |item_id|
      # We need to index the identifier element value to be able to search in Solr and then retrieve the document by id
      solr_query = "marc_id_tesim:\"#{item_id.to_s}\""
      solr_query << " AND #{Solrizer.solr_name('root_collection_id', :stored_searchable, type: :string)}:\"#{root_collection.to_s}\""
      marc_item = ActiveFedora::SolrService.query(solr_query, :defType => "edismax")

      if marc_item.empty?
        Rails.logger.error("Relationship target object #{item_id} not found in Solr for object #{self.pid}")
      else
        doc = SolrDocument.new(marc_item[0])
        # Cast the solr document to its corresponding Fedora object
        marc_obj = DRI::Marc.find(doc.id)
        unless qdc_obj == nil
          if self.send("#{rels_name}").respond_to?("push")
            self.send("#{rels_name}").push marc_obj
          else
            self.send("#{rels_name}=", marc_obj)
          end

          self.save if self.valid?
        end
      end
    end
  end # end add_dm_relationship

  def get_relationships_names
    return {:related => "Is Related To",
            :version => "Is Version Of",
            :format_of => "Is Format Of"
    }
  end

  def create_multiple_records
    yield

    full_metadata_no_ns = self.fullMetadata.ng_xml.clone
    full_metadata_no_ns.remove_namespaces!
    if !new_record? && full_metadata_no_ns.search("//record").count > 1
      begin
        Sufia.queue.push(CreateMarcRecordsJob.new(self.pid))
      rescue Exception => e
      end
    end
  end
      
end
end
