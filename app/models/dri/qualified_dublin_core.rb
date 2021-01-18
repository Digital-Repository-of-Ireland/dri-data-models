# DRI namespace
module DRI
  # Implementation of DRI Qualified Dublin Core digital objects
  class QualifiedDublinCore < DRI::DigitalObject
    has_one :descMetadata, class_name: 'DRI::Metadata::QualifiedDublinCore', as: :describable, autosave: true

    # Full Simple DC Title, Creator, Subject, Description, Publisher,
    # Contributor, Date, Type, Format, Identifier, Source,
    # Language, Relation, Coverage, Rights
    # All DC elements added to the DM - Simple DC Ingest form
    delegate :date,:date=, to: :descMetadata
    delegate :relation,:relation=, to: :descMetadata
    delegate :external_relation,:external_relation=, to: :descMetadata
    delegate :source,:source=, to: :descMetadata
    delegate :geographical_coverage,:geographical_coverage=, to: :descMetadata
    delegate :temporal_coverage,:temporal_coverage=, to: :descMetadata
    delegate :name_coverage,:name_coverage=, to: :descMetadata
    delegate :resource_type,:resource_type=, to: :descMetadata
    delegate :format,:format=, to: :descMetadata
    delegate :coverage,:coverage=, to: :descMetadata
    delegate :identifier,:identifier=, to: :descMetadata
    delegate :resource_type,:resource_type=, to: :descMetadata
    # id_asset is used for sorting digital objects by order/sequence
    # used in catalog_controller in the dri-app
    delegate :id_asset=, to: :descMetadata
    delegate :qdc_id,:qdc_id=, to: :descMetadata
    delegate :geocode_point,:geocode_point=, to: :descMetadata
    delegate :geocode_box,:geocode_box=, to: :descMetadata

    delegate :published_date,:published_date=, to: :descMetadata
    delegate :creation_date,:creation_date=, to: :descMetadata

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

    def id_asset
      descMetadata.id_asset.first
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

    # Retrieve an existing DRI::QualifiedDublinCore object;
    # creates a new one if object not found for a given PID
    #
    # @param [String] pid the object's PID
    # @return [DRI::QualifiedDublinCore] the retrieved object; new object if not found
    def self.find_or_create(pid)
      DRI::Identifier.retrieve_object!(pid)
    rescue ActiveRecord::RecordNotFound
      DRI::QualifiedDublinCore.create(alternate_id: pid)
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
      Solrizer.solr_name('qdc_id', :stored_searchable, type: :string)
    end
  end # class
end # module
