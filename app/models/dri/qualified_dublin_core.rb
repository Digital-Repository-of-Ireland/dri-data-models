# DRI namespace
module DRI
  # Implementation of DRI Marc digital objects extending from DRI::Batch
  class QualifiedDublinCore < DRI::Batch

    contains 'descMetadata', class_name: 'DRI::Metadata::QualifiedDublinCore'

    # Full Simple DC Title, Creator, Subject, Description, Publisher,
    # Contributor, Date, Type, Format, Identifier, Source,
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
      { related: retrieve_relation_records(send(self.class.relationships[:related][:field]), self.class.solr_relationships_field),
        referenced: retrieve_relation_records(send(self.class.relationships[:referenced][:field]), self.class.solr_relationships_field),
        references: retrieve_relation_records(send(self.class.relationships[:references][:field]), self.class.solr_relationships_field),
        container: retrieve_relation_records(send(self.class.relationships[:container][:field]), self.class.solr_relationships_field),
        parts: retrieve_relation_records(send(self.class.relationships[:parts][:field]), self.class.solr_relationships_field),
        is_version: retrieve_relation_records(send(self.class.relationships[:is_version][:field]), self.class.solr_relationships_field),
        has_versions: retrieve_relation_records(send(self.class.relationships[:has_versions][:field]), self.class.solr_relationships_field),
        is_format: retrieve_relation_records(send(self.class.relationships[:is_format][:field]), self.class.solr_relationships_field),
        has_format: retrieve_relation_records(send(self.class.relationships[:has_format][:field]), self.class.solr_relationships_field),
        has_source: retrieve_relation_records(send(self.class.relationships[:has_source][:field]), self.class.solr_relationships_field)
      }
    end
  end # class
end # module
