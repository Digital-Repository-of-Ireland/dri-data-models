# DRI namespace
module DRI
  # Implementation of DRI Qualified Dublin Core digital objects extending from DRI::Batch
  class QualifiedDublinCore < DRI::Batch

    contains 'descMetadata', class_name: 'DRI::Metadata::QualifiedDublinCore'

    # Full Simple DC Title, Creator, Subject, Description, Publisher,
    # Contributor, Date, Type, Format, Identifier, Source,
    # Language, Relation, Coverage, Rights
    # All DC elements added to the DM - Simple DC Ingest form
    property :date, delegate_to: 'descMetadata', multiple: true
    property :relation, delegate_to: 'descMetadata', multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_displayable, DRI::Metadata::Descriptors.cleaned_facetable
    end
    property :external_relation, delegate_to: 'descMetadata', multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_displayable, DRI::Metadata::Descriptors.cleaned_facetable
    end
    property :source, delegate_to: 'descMetadata', multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable
    end
    property :geographical_coverage, delegate_to: 'descMetadata', multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable, 
               DRI::Metadata::Descriptors.cleaned_facetable, DRI::Metadata::Descriptors.cleaned_displayable
    end
    property :temporal_coverage, delegate_to: 'descMetadata', multiple: true
    property :name_coverage, delegate_to: 'descMetadata', multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_facetable, 
               DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable
    end
    property :resource_type, delegate_to: 'descMetadata', multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_facetable, 
               DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable
    end
    property :format, delegate_to: 'descMetadata', multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_facetable, 
               DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable
    end
    property :coverage, delegate_to: 'descMetadata', multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable
    end
    property :identifier, delegate_to: 'descMetadata', multiple: true

    # id_asset is used for sorting digital objects by order/sequence
    # used in catalog_controller in the dri-app
    property :id_asset, delegate_to: 'descMetadata', multiple: false do |index|
      index.as :stored_sortable
    end
    property :qdc_id, delegate_to: 'descMetadata', multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable
    end
    property :geocode_point, delegate_to: 'descMetadata', multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable
    end
    property :geocode_box, delegate_to: 'descMetadata', multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable
    end

    class_eval do
      # Dynamically populate the marcrelator code model attributes
      # e.g. role_cre (creator), role_ctb (contributor), ...
      DRI::Vocabulary.marc_relators.map { |s| property s.prepend('role_').to_sym,
                                                       delegate_to: 'descMetadata',
                                                       multiple: true }
      # Internal Relationships (dynamically populate the model attributes)
      DRI::Vocabulary.qdc_relationship_types.map { |s| property s.prepend('relation_ids_').to_sym,
                                                                delegate_to: 'descMetadata',
                                                                multiple: true }
      # External relationships (contain a URI to resources external to DRI)
      # (dynamically populate the model attributes)
      DRI::Vocabulary.qdc_relationship_types.map { |s| property s.prepend('ext_related_items_ids_').to_sym,
                                                                delegate_to: 'descMetadata',
                                                                multiple: true }
    end

    # Override constructor
    def initialize(args = {})
      args[:desc_metadata_class] = 'DRI::Metadata::QualifiedDublinCore'
      super(args)
    end

    #
    # @return [String] the AF digital object model name
    def model_name
      DRI::Batch.model_name
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
      updated_props.keys.each do |k|
        next if k.to_sym != :type

        updated_props[:resource_type] = updated_props[k]
        updated_props.delete(k)
        break
      end

      super(properties)
    end

    # Retrieve an existing Fedora DRI::QualifiedDublinCore object;
    # creates a new one if object not found for a given PID
    #
    # @param [String] pid the object's PID
    # @return [DRI::QualifiedDublinCore] the retrieved Fedora object; new object if not found
    def self.find_or_create(pid)
      obj = DRI::QualifiedDublinCore.find(pid)
    rescue ActiveFedora::ObjectNotFoundError
      DRI::QualifiedDublinCore.create(id: pid)
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
      self.resource_type = type
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
