module DRI
  class Documentation < DRI::Batch
    # Override interchangeable_metadata definition of descMetadata
    contains 'descMetadata', class_name: 'DRI::Metadata::Documentation'

    belongs_to :documentation_for,
               predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isDescriptionOf,
               class_name: 'DRI::Batch'

    property :date, delegate_to: 'descMetadata', multiple: true
    property :source, delegate_to: 'descMetadata', multiple: true
    property :geographical_coverage, delegate_to: 'descMetadata', multiple: true
    property :temporal_coverage, delegate_to: 'descMetadata', multiple: true
    property :temporal_coverage_period, delegate_to: 'descMetadata', multiple: true
    property :resource_type, delegate_to: 'descMetadata', multiple: true
    property :format, delegate_to: 'descMetadata', multiple: true
    property :coverage, delegate_to: 'descMetadata', multiple: true
    property :identifier, delegate_to: 'descMetadata', multiple: true
    property :geocode_point, delegate_to: 'descMetadata', multiple: true
    property :geocode_box, delegate_to: 'descMetadata', multiple: true
    property :relation, delegate_to: 'descMetadata', multiple: true

    class_eval do
      DRI::Vocabulary.marc_relators.map do |s|
        property s.prepend('role_').to_sym,
                 delegate_to: 'descMetadata',
                 multiple: true
      end
    end

    def initialize(args = {})
      args[:desc_metadata_class] = 'DRI::Metadata::Documentation'
      super(args)
    end

    def update_metadata(xml_text, ingest = true)
    end

    def attributes=(properties)
      updated_props = properties.clone
      point_hash = { geocode_point: [] }
      box_hash = { geocode_box: [] }
      period_hash = { temporal_coverage_period: [] }

      # When updating from DRI form
      # replace type attribute key with resource_type
      updated_props.keys.each do |k|
        next if k.to_sym != :type

        updated_props[:resource_type] = updated_props[k]
        updated_props.delete(k)
        break
      end

      # Adding :geocode_point and :geocode_box to properties
      # if :geographical_coverage present
      # for spatial indexing
      if updated_props[:geographical_coverage].present?
        updated_props[:geographical_coverage].each do |item|
          point_hash[:geocode_point] << item if DRI::Metadata::Transformations.dcmi_point?(item)
          box_hash[:geocode_box] << item if DRI::Metadata::Transformations.dcmi_box?(item)
        end
      end

      # Adding :temporal_coverage_period to properties
      # if :temporal_coverage present
      # for temporal indexing
      if updated_props[:temporal_coverage].present?
        updated_props[:temporal_coverage].each do |item|
          next unless DRI::Metadata::Transformations.dcmi_period?(item)

          period_hash[:temporal_coverage_period] << item
        end
      end
      # avoid overwriting entries with duplicate keys
      if point_hash[:geocode_point].present?
        updated_props.merge!(point_hash) { |_k, v0, _v2| v0 }
      end
      if box_hash[:geocode_box].present?
        updated_props.merge!(box_hash) { |_k, v0, _v2| v0 }
      end
      if period_hash[:temporal_coverage_period].present?
        updated_props.merge!(period_hash) { |_k, v0, _v2| v0 }
      end

      super(updated_props)
    end

    def roles=(roles)
      descMetadata.roles = roles if descMetadata.is_a?(DRI::Metadata::Documentation)
    end

    def type
      descMetadata.resource_type
    end

    def type=(type)
      self.resource_type = type
    end

    def self.find_or_create(pid)
      DRI::Documentation.find(pid)
    rescue ActiveFedora::ObjectNotFoundError
      DRI::Documentation.create(id: pid)
    end

    def to_solr(solr_doc = {}, opts = {})
      super(solr_doc, opts)
    end

    # Override from interchangeable_metadata:
    # descMetadata doesn't inherit from base
    # and it loads the correct class
    def load_attributes
    end

    # Override from interchangeable_metadata
    # Documentation does not inherit from DRI::Metadata::Base
    def custom_validations
      results = descMetadata.custom_validations
      return true if results.empty?

      results.each { |key, value| errors.add(key, value) }
      false
    end # custom_validations
  end
end
