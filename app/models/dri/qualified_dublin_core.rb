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
    has_attributes :name_coverage, datastream: :descMetadata, multiple: true
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
    has_and_belongs_to_many :related, predicate: ::RDF::DC.relation, class_name: "DRI::QualifiedDublinCore"
    has_and_belongs_to_many :referenced, predicate: ::RDF::DC.isReferencedBy, class_name: "DRI::QualifiedDublinCore"
    has_and_belongs_to_many :references, predicate: ::RDF::DC.references, class_name: "DRI::QualifiedDublinCore"

    belongs_to :container, predicate: ::RDF::DC.isPartOf, class_name: "DRI::QualifiedDublinCore"
    has_many :parts, predicate: ::RDF::DC.isPartOf, class_name: "DRI::QualifiedDublinCore", as: :container

    belongs_to :is_version, predicate: ::RDF::DC.isVersionOf, class_name: "DRI::QualifiedDublinCore"
    has_many :has_versions, predicate: ::RDF::DC.isVersionOf, class_name: "DRI::QualifiedDublinCore", as: :is_version

    belongs_to :is_format, predicate: ::RDF::DC.isFormatOf, class_name: "DRI::QualifiedDublinCore"
    has_many :has_format, predicate: ::RDF::DC.isFormatOf, class_name: "DRI::QualifiedDublinCore", as: :is_format

    belongs_to :source_rel, predicate: ::RDF::DC.source, class_name: "DRI::QualifiedDublinCore"

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
        DRI::QualifiedDublinCore.create({id: pid})
      end
    end

    # Iterate over every collection's object and process relationships
    #
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
            object = DRI::QualifiedDublinCore.find(doc.id)
            begin
              Sufia.queue.push(CreateQdcRelationshipsJob.new(object.id))
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
      add_dm_relationship(relation_ids_relation, :related)
      add_dm_relationship(relation_ids_isPartOf, :container)
      #add_dm_relationship(relation_ids_hasPart, :parts)
      add_dm_relationship(relation_ids_isReferencedBy, :referenced)
      add_dm_relationship(relation_ids_references, :references)
      add_dm_relationship(relation_ids_isVersionOf, :is_version)
      #add_dm_relationship(relation_ids_hasVersion, :has_versions)
      add_dm_relationship(relation_ids_isFormatOf, :is_format)
      #add_dm_relationship(relation_ids_hasFormat, :has_format)
      add_dm_relationship(relation_ids_source, :source_rel)

      # After processing all the relationships for the object, save
      self.save if self.valid?
    end

    # Process a specific qdc relationship for the object
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

      # Get Root collection of current object.
      # This is to restrict relationship processing only within the given collection
      solr_query = "id:\"#{id.to_s}\""
      # The query service returns back a set of Solr Documents, therefore need to be casted later on
      solr_docs = ActiveFedora::SolrService.query(solr_query, :defType => "edismax")

      if (solr_docs == nil || solr_docs == [])
        Rails.logger.error("Solr document for object with PID #{self.id} not found in Solr")
        return
      end

      doc = SolrDocument.new(solr_docs[0])
      root_collection = doc[ActiveFedora::SolrQueryBuilder.solr_name('root_collection_id', :stored_searchable, type: :string)]

      if (root_collection == nil)
        Rails.logger.error("Root collection ID for object with PID #{self.id} not found in Solr")
        return
      end

      rels_array.each do |item_id|
        # We need to index the identifier element value to be able to search in Solr and then retrieve the document by id
        solr_query = "#{ActiveFedora::SolrQueryBuilder.solr_name('qdc_id', :stored_searchable, type: :string)}:\"#{item_id.to_s}\""
        solr_query << " AND #{ActiveFedora::SolrQueryBuilder.solr_name('root_collection_id', :stored_searchable, type: :string)}:\"#{root_collection.first.to_s}\""
        qdc_item = ActiveFedora::SolrService.query(solr_query, :defType => "edismax")

        if qdc_item.empty?
          Rails.logger.error("Relationship target object #{item_id} not found in Solr for object #{self.id}")
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
              #self.association(:governing_collection).replace(qdc_obj)
            else
              if self.send("#{rels_name}").respond_to?("push")
                self.send("#{rels_name}").push qdc_obj
              else
                self.send("#{rels_name}=", qdc_obj)
              end
            end

            # Save object, if valid
            #self.save if self.valid?
          end
        end
      end
    end # end add_dm_relationship

    def get_relationships_names
      return {:related => "Is Related To",
              :referenced => "Is Referenced By",
              :references => "References",
              :container => "Is Part Of",
              :parts => "Has Part",
              :is_version => "Is Version Of",
              :has_versions => "Has Version",
              :is_format => "Is Format Of",
              :has_format => "Has Format",
              :source_rel => "Source"
      }
    end
      
  end # Class QualifiedDublinCore
end # Module DRI
