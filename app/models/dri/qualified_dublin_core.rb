# DRI namespace
module DRI
  # Implementation of DRI Qualified Dublin Core digital objects extending from DRI::Base
  class QualifiedDublinCore < DRI::DigitalObject

    has_one :descMetadata, class_name: 'DRI::Metadata::QualifiedDublinCore', as: :describable, autosave: true
    
    # Full Simple DC Title, Creator, Subject, Description, Publisher,
    # Contributor, Date, Type, Format, Identifier, Source,
    # Language, Relation, Coverage, Rights
    # All DC elements added to the DM - Simple DC Ingest form
    delegate :creator,:creator=, to: :descMetadata
    delegate :date,:date=, to: :descMetadata
    delegate :relation,:relation=, to: :descMetadata
    delegate :external_relation,:external_relation=, to: :descMetadata
    delegate :source,:source=, to: :descMetadata
    delegate :geographical_coverage,:geographical_coverage=, to: :descMetadata
    delegate :temporal_coverage,:temporal_coverage=, to: :descMetadata
    delegate :temporal_coverage_period,:temporal_coverage_period=, to: :descMetadata
    delegate :name_coverage,:name_coverage=, to: :descMetadata
    delegate :resource_type,:resource_type=, to: :descMetadata
    delegate :format,:format=, to: :descMetadata
    delegate :coverage,:coverage=, to: :descMetadata
    delegate :identifier,:identifier=, to: :descMetadata
    # id_asset is used for sorting digital objects by order/sequence
    # used in catalog_controller in the dri-app
    delegate :id_asset,:id_asset=, to: :descMetadata
    delegate :qdc_id,:qdc_id=, to: :descMetadata
    delegate :geocode_point,:geocode_point=, to: :descMetadata
    delegate :geocode_box,:geocode_box=, to: :descMetadata

    delegate :published_date,:published_date=, to: :descMetadata
    delegate :creation_date,:creation_date=, to: :descMetadata
    class_eval do
      # Dynamically populate the marcrelator code model attributes
      # e.g. role_cre (creator), role_ctb (contributor), ...
      DRI::Vocabulary.marc_relators.map { |s| delegate s.prepend('role_').to_sym,s.concat('=').to_sym,
                                                       to: :descMetadata}
      # Internal Relationships (dynamically populate the model attributes)
      DRI::Vocabulary.qdc_relationship_types.map { |s| delegate s.prepend('relation_ids_').to_sym,s.concat('=').to_sym,
                                                                to: :descMetadata}
      # External relationships (contain a URI to resources external to DRI)
      # (dynamically populate the model attributes)
      DRI::Vocabulary.qdc_relationship_types.map { |s| delegate s.prepend('ext_related_items_ids_').to_sym,s.concat('=').to_sym,
                                                                to: :descMetadata}
    end
   
    def descMetadata
      super || build_descMetadata
    end

    def fullMetadata
      super || build_fullMetadata
    end

    #
    # @return [String] the AF digital object model name
    def model_name
      DRI::DigitalObject.model_name
    end

    # Roles attribute setter
    #
    # @param [Hash] roles hash with metadata marcrelator values
    # @option roles [Array<String>] :name the metadata values for the marcrelators in :type
    # @option roles [Array<String>] :type the marcrelator codes
    def roles=(roles)
      descMetadata.roles = roles if descMetadata.is_a?(DRI::Metadata::QualifiedDublinCore)
    end

    # Override AF attributes setter
    def attributes=(properties)
      updated_props = properties.clone

      # When updating from DRI form
      # replace type attribute key with resource_type
      updated_props[:resource_type] = updated_props.delete :type

      super(updated_props)
    end

    # Retrieve an existing Fedora DRI::QualifiedDublinCore object;
    # creates a new one if object not found for a given PID
    #
    # @param [String] pid the object's PID
    # @return [DRI::QualifiedDublinCore] the retrieved Fedora object; new object if not found
    def self.find_or_create(pid)
      DRI::QualifiedDublinCore.find_by!(noid: pid)
    rescue ActiveRecord::RecordNotFound
      DRI::QualifiedDublinCore.create(noid: pid)
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

    # For relationships display in the UI, creates Hash where the keys are
    # relationship names, which contain a displayable label and the model metadata field
    # for the given relationship
    #
    # @return [Hash] relationships hash including label/field
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

    # Return the solr field name for the mods identifier used in metadata QDC relationships
    # i.e. qdc_id_tesim
    # @return [String] AF solrizer solr index field name
    def self.solr_relationships_field
      ActiveFedora.index_field_mapper.solr_name('qdc_id', :stored_searchable, type: :string)
    end

    # Return a Hash including all the PIDs of fedora objects by relationship type
    # @return [Hash] the hash of QDC relationships with the Fedora PIDs of the related objects
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
