module DRI
  class QualifiedDublinCore < DRI::Batch

    # Full Simple DC Title, Creator, Subject, Description, Publisher, Contributor, Date, Type, Format, Identifier, Source,
    # Language, Relation, Coverage, Rights
    # All DC elements added to the DM - Simple DC Ingest form
    has_attributes :date, datastream: :descMetadata, multiple: true
    has_attributes :relation, datastream: :descMetadata, multiple: true
    has_attributes :external_relation, datastream: :descMetadata, multiple: true
    has_attributes :source, datastream: :descMetadata, multiple: true
    has_attributes :geographical_coverage, datastream: :descMetadata, multiple: true
    has_attributes :temporal_coverage, datastream: :descMetadata, multiple: true
    has_attributes :type, datastream: :descMetadata, multiple: true
    has_attributes :format, datastream: :descMetadata, multiple: true
    has_attributes :coverage, datastream: :descMetadata, multiple: true
    has_attributes :identifier, datastream: :descMetadata, multiple: true
    # Used for relationships
    has_attributes :qdc_id, datastream: :descMetadata, multiple: true
    has_attributes :geocode_point, datastream: :descMetadata, multiple: true
    has_attributes :geocode_box, datastream: :descMetadata, multiple: true
    has_attributes  *(DRI::Vocabulary::marcRelators.map { |s| s.prepend("role_").to_sym}), datastream: :descMetadata,
                                   multiple: true

    # Internal Relationships
    has_attributes  *(DRI::Vocabulary::qdcRelationshipTypes.map { |s| s.prepend("relation_ids_").to_sym}),
                    datastream: :descMetadata, multiple: true

    # External relationships (contain a URI to resources external to DRI)
    has_attributes *(DRI::Vocabulary::qdcRelationshipTypes.map { |s| s.prepend("ext_related_items_ids_").to_sym}),
                   datastream: :descMetadata, multiple: true

    # QDC Relationships
    has_many :related, :property=>:dcterms_relation, :class_name => "DRI::QualifiedDublinCore"
    has_many :referenced, :property=>:dcterms_is_referenced_by, :class_name => "DRI::QualifiedDublinCore"
    has_many :references, :property=>:dcterms_references, :class_name => "DRI::QualifiedDublinCore"

    belongs_to :container, :property=>:dcterms_is_part_of, :class_name => "DRI::QualifiedDublinCore"
    # hasPart is managed through the isPartOf relationship. This automatically adds the child isPartOf
    # whenever a hasPart relationship is added
    has_many :parts, :property=>:dcterms_is_part_of, :class_name => "DRI::QualifiedDublinCore"

    has_many :version, :property=>:dcterms_is_version_of, :class_name => "DRI::QualifiedDublinCore"
    has_many :versions, :property=>:dcterms_has_version, :class_name => "DRI::QualifiedDublinCore"
    has_many :format_of, :property=>:dcterms_is_format_of, :class_name => "DRI::QualifiedDublinCore"

    def initialize(args = {})
      args[:desc_metadata_class] = "DRI::Metadata::QualifiedDublinCore"
      super(args)
    end

    def model_name
      DRI::Batch.model_name
    end

    def roles= roles
      if descMetadata.class == DRI::Metadata::QualifiedDublinCore
        descMetadata.roles = roles
      end
    end

    def attributes=(properties)
      super(properties)
    end

    def self.find_or_create(pid)
      begin
        DRI::QualifiedDublinCore.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
        DRI::QualifiedDublinCore.create({pid: pid})
      end
    end

    # Iterate over every collection's object and process relationships
    #
    def process_collection_relationships
      if self.is_root_collection?
        # Get all the collection's objects
        # We need to index the mods element ID to be able to search in Solr and then retrieve the document by id
        solr_query = "#{Solrizer.solr_name('root_collection_id', :stored_searchable, type: :string)}:\"#{self.pid.to_s}\""

        # collection_objects_docs = ActiveFedora::SolrService.query(solr_query, :defType => "edismax")
        query = Solr::Query.new(solr_query)
        while (query.has_more?)
          collection_objects_docs = query.pop
          collection_objects_docs.each do |obj_doc|
            doc = SolrDocument.new(obj_doc)
            object = DRI::Mods.find(doc.id)
            begin
              Sufia.queue.push(CreateQdcRelationshipsJob.new(object.pid))
            rescue Exception => e
              logger.error(e.message)
            end
          end
        end
      else
        # Only process the object's relationships
        Sufia.queue.push(CreateQdcRelationshipsJob.new(self.pid))
        # Logger.error("The object #{self.pid} is not a collection container.")
      end
    end # end add_relationships

    def process_relationships()
      add_dm_relationship(relation_ids_isRelatedTo, :related)
      add_dm_relationship(relation_ids_isPartOf, :container)
      add_dm_relationship(relation_ids_hasPart, :parts)
      add_dm_relationship(relation_ids_isReferencedBy, :referenced)
      add_dm_relationship(relation_ids_references, :references)
      add_dm_relationship(relation_ids_isVersionOf, :version)
      add_dm_relationship(relation_ids_hasVersion, :versions)
      add_dm_relationship(relation_ids_isFormatOf, :format_of)
    end

    # Process a specific mods relationship for the object
    # @return true if successful; false otherwise
    #
    def add_dm_relationship(rels_array, rels_name)
      if rels_array.empty?
        return true
      end

      # Get Root collection
      solr_query = "id:\"#{pid.to_s}\""
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
        # We need to index the identifier element value to be able to search in Solr and then retrieve the document by id
        solr_query = "qdc_id_tesim:\"#{item_id.to_s}\" "+
            "AND #{Solrizer.solr_name('root_collection_id', :stored_searchable, type: :string)}:\"#{root_collection.to_s}\""
        qdc_item = ActiveFedora::SolrService.query(solr_query, :defType => "edismax")

        if qdc_item.empty?
          logger.error("Relationship target object #{item_id} not found in Solr for object #{self.pid}")
          return false
        else
          doc = SolrDocument.new(qdc_item[0])
          # Cast the solr document to its corresponding Fedora object
          qdc_obj = DRI::QualifiedDublinCore.find(doc.id)
          unless qdc_obj == nil
            if (rels_name.equal?(:parts))
              qdc_obj.send("#{:container}=", self)
              qdc_obj.save if qdc_obj.valid?
            elsif rels_name.equal?(:container)
              self.send("#{rels_name}=", qdc_obj)
              self.governing_collection = qdc_obj
            else
              if self.send("#{rels_name}").respond_to?("push")
                self.send("#{rels_name}").push qdc_obj
              else
                self.send("#{rels_name}=", qdc_obj)
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
    end # end add_dm_relationship

    def get_relationships_names
      return {:related => "Is Related To",
              :referenced => "Is Referenced By",
              :references => "References",
              :container => "Is Part Of",
              :parts => "Has Part",
              :version => "Is Version Of",
              :versions => "Has Version",
              :format_of => "Is Format Of"
      }
    end
      
  end # Class QualifiedDublinCore
end # Module DRI
