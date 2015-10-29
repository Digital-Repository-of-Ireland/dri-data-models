module DRI
  class QualifiedDublinCore < DRI::Batch

    contains 'descMetadata', class_name: 'DRI::Metadata::QualifiedDublinCore'

    # Full Simple DC Title, Creator, Subject, Description, Publisher, Contributor, Date, Type, Format, Identifier, Source,
    # Language, Relation, Coverage, Rights
    # All DC elements added to the DM - Simple DC Ingest form
    property :date, delegate_to: 'descMetadata', multiple: true
    property :relation, delegate_to: 'descMetadata', multiple: true
    property :external_relation, delegate_to: 'descMetadata', multiple: true
    property :source, delegate_to: 'descMetadata', multiple: true
    property :geographical_coverage, delegate_to: 'descMetadata', multiple: true
    property :temporal_coverage, delegate_to: 'descMetadata', multiple: true
    property :name_coverage, delegate_to: 'descMetadata', multiple: true
    property :type, delegate_to: 'descMetadata', multiple: true
    property :format, delegate_to: 'descMetadata', multiple: true
    property :coverage, delegate_to: 'descMetadata', multiple: true
    property :identifier, delegate_to: 'descMetadata', multiple: true
    # Used for relationships
    property :id_asset, delegate_to: 'descMetadata', multiple: false
    property :qdc_id, delegate_to: 'descMetadata', multiple: true
    property :geocode_point, delegate_to: 'descMetadata', multiple: true
    property :geocode_box, delegate_to: 'descMetadata', multiple: true

    class_eval do
      DRI::Vocabulary.marc_relators.map { |s| property s.prepend('role_').to_sym, delegate_to: 'descMetadata', multiple: true }
      # Internal Relationships
      DRI::Vocabulary.qdc_relationship_types.map { |s| property s.prepend('relation_ids_').to_sym, delegate_to: 'descMetadata', multiple: true }
      # External relationships (contain a URI to resources external to DRI)
      DRI::Vocabulary.qdc_relationship_types.map { |s| property s.prepend('ext_related_items_ids_').to_sym, delegate_to: 'descMetadata', multiple: true }
    end

    # QDC Relationships
    # has_and_belongs_to_many :related, predicate: ::RDF::DC.relation, class_name: "DRI::QualifiedDublinCore"
    # has_and_belongs_to_many :referenced, predicate: ::RDF::DC.isReferencedBy, class_name: "DRI::QualifiedDublinCore"
    # has_and_belongs_to_many :references, predicate: ::RDF::DC.references, class_name: "DRI::QualifiedDublinCore"

    # belongs_to :container, predicate: ::RDF::DC.isPartOf, class_name: "DRI::QualifiedDublinCore"
    # has_many :parts, predicate: ::RDF::DC.isPartOf, class_name: "DRI::QualifiedDublinCore", as: :container

    # belongs_to :is_version, predicate: ::RDF::DC.isVersionOf, class_name: "DRI::QualifiedDublinCore"
    # has_many :has_versions, predicate: ::RDF::DC.isVersionOf, class_name: "DRI::QualifiedDublinCore", as: :is_version

    # belongs_to :is_format, predicate: ::RDF::DC.isFormatOf, class_name: "DRI::QualifiedDublinCore"
    # has_many :has_format, predicate: ::RDF::DC.isFormatOf, class_name: "DRI::QualifiedDublinCore", as: :is_format

    # belongs_to :has_source, predicate: ::RDF::DC.source, class_name: "DRI::QualifiedDublinCore"
    # has_many :source_for, predicate: ::RDF::DC.source, class_name: "DRI::QualifiedDublinCore", as: :has_source

    def initialize(args = {})
      args[:desc_metadata_class] = 'DRI::Metadata::QualifiedDublinCore'
      super(args)
    end

    def model_name
      DRI::Batch.model_name
    end

    def roles=(roles)
      descMetadata.roles = roles if descMetadata.is_a?(DRI::Metadata::QualifiedDublinCore)
    end

    def attributes=(properties)
      super(properties)
    end

    def self.find_or_create(pid)
      DRI::QualifiedDublinCore.find(pid)
    rescue ActiveFedora::ObjectNotFoundError
      DRI::QualifiedDublinCore.create(id: pid)
    end

=begin
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
      #add_dm_relationship(relation_ids_relation, :related)
      #add_dm_relationship(relation_ids_isPartOf, :container)
      ##add_dm_relationship(relation_ids_hasPart, :parts)
      #add_dm_relationship(relation_ids_isReferencedBy, :referenced)
      #add_dm_relationship(relation_ids_references, :references)
      #add_dm_relationship(relation_ids_isVersionOf, :is_version)
      ##add_dm_relationship(relation_ids_hasVersion, :has_versions)
      #add_dm_relationship(relation_ids_isFormatOf, :is_format)
      ##add_dm_relationship(relation_ids_hasFormat, :has_format)
      #add_dm_relationship(relation_ids_source, :has_source)

      # After processing all the relationships for the object, save
      #self.save if self.valid?
    end
=end

    def self.relationships
      { related: { label: 'Is Related To', field: 'relation_ids_relation' },
        referenced: { label: 'Is Referenced By', field: 'relation_ids_isReferencedBy' },
        references: { label: 'References', field: 'relation_ids_references' },
        container: { label: 'Is Part Of', field: 'relation_ids_isPartOf' },
        parts: { label: 'Has Part', field: 'relation_ids_hasPart' },
        is_version: { label: 'Is Version Of', field: 'relation_ids_isVersionOf' },
        has_versions: { label: 'Has Version', field: 'relation_ids_hasVersion' },
        is_format: { label: 'Is Format Of', field: 'relation_ids_isFormatOf' },
        has_format: { label: 'Has Format', field: 'relation_ids_hasFormat' },
        has_source: { label: 'Source', field: 'relation_ids_source' }
      }
    end

    def self.solr_relationships_field
      ActiveFedora::SolrQueryBuilder.solr_name('qdc_id', :stored_searchable, type: :string)
    end

    def get_relationships_records
      { related: retrieve_relation_records(relation_ids_relation, self.class.solr_relationships_field),
        referenced: retrieve_relation_records(relation_ids_isReferencedBy, self.class.solr_relationships_field),
        references: retrieve_relation_records(relation_ids_references, self.class.solr_relationships_field),
        container: retrieve_relation_records(relation_ids_isPartOf, self.class.solr_relationships_field),
        parts: retrieve_relation_records(relation_ids_hasPart, self.class.solr_relationships_field),
        is_version: retrieve_relation_records(relation_ids_isVersionOf, self.class.solr_relationships_field),
        has_versions: retrieve_relation_records(relation_ids_hasVersion, self.class.solr_relationships_field),
        is_format: retrieve_relation_records(relation_ids_isFormatOf, self.class.solr_relationships_field),
        has_format: retrieve_relation_records(relation_ids_hasFormat, self.class.solr_relationships_field),
        has_source: retrieve_relation_records(relation_ids_source, self.class.solr_relationships_field)
      }
    end

    private

    # Process a specific qdc relationship for the object
    #
    def add_dm_relationship(rels_array, rels_name)
      # Reset previous relationships
      if send("#{rels_name}").respond_to?('push')
        send("#{rels_name}").clear
      else
        association(rels_name.to_sym).replace(nil)
      end

      return if rels_array.empty?

      # Get Root collection of current object.
      # This is to restrict relationship processing only within the given collection
      solr_query = "id:\"#{id}\""
      # The query service returns back a set of Solr Documents, therefore need to be casted later on
      solr_docs = ActiveFedora::SolrService.query(solr_query, defType: 'edismax')

      if solr_docs.nil? || solr_docs.empty?
        Rails.logger.error("Solr document for object with PID #{id} not found in Solr")
        return
      end

      doc = SolrDocument.new(solr_docs[0])
      root_collection = doc[ActiveFedora::SolrQueryBuilder.solr_name('root_collection_id', :stored_searchable, type: :string)]

      if root_collection.nil?
        Rails.logger.error("Root collection ID for object with PID #{id} not found in Solr")
        return
      end

      rels_array.each do |item_id|
        # We need to index the identifier element value to search in Solr
        # and then retrieve the document by id
        solr_query = "#{ActiveFedora::SolrQueryBuilder.solr_name('qdc_id', :stored_searchable, type: :string)}:\"#{item_id}\""
        solr_query << " AND #{ActiveFedora::SolrQueryBuilder.solr_name('root_collection_id', :stored_searchable, type: :string)}:\"#{root_collection.first}\""

        qdc_item = ActiveFedora::SolrService.query(solr_query, defType: 'edismax')

        if qdc_item.empty?
          Rails.logger.error("Relationship target object #{item_id} not found in Solr for object #{id}")
        else
          doc = SolrDocument.new(qdc_item[0])
          # Cast the solr document to its corresponding Fedora object
          qdc_obj = DRI::QualifiedDublinCore.find(doc.id)

          next if qdc_obj.nil?

          if rels_name.equal?(:parts)
            qdc_obj.send("#{:container}=", self)
            qdc_obj.save if qdc_obj.valid?
          elsif rels_name.equal?(:container)
            send("#{rels_name}=", qdc_obj)
            # association(:governing_collection).replace(qdc_obj)
          else
            if send("#{rels_name}").respond_to?('push')
              send("#{rels_name}").push qdc_obj
            else
              send("#{rels_name}=", qdc_obj)
            end
          end

          # Save object, if valid
          # self.save if self.valid?
        end
      end
    end # end add_dm_relationship
  end # Class QualifiedDublinCore
end # Module DRI
