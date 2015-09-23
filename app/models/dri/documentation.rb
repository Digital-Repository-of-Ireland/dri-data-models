module DRI
  class Documentation < DRI::Batch

    # Override interchangeable_metadata definition of descMetadata
    contains 'descMetadata', class_name: 'DRI::Metadata::Documentation'

    belongs_to :documentation_for, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isDescriptionOf, class_name: 'DRI::Batch'

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

    self.class_eval do
      DRI::Vocabulary::marcRelators.map { |s| property s.prepend('role_').to_sym, delegate_to: 'descMetadata', multiple: true }
    end

    def attributes=(properties)
      point_hash = Hash.new
      box_hash = Hash.new
      period_hash = Hash.new

      # When updating from DRI form, type attribute key needs to be replaced with resource_type
      properties.keys.each do |k|
        if k.to_sym == :type
          properties[:resource_type] = properties[k]
          properties.delete(k)
          break
        end
      end
      # Adding :geocode_point and :geocode_box to properties if :geographical_coverage present
      # for spatial indexing
      if !properties[:geographical_coverage].nil? && !properties[:geographical_coverage].empty?
        properties[:geographical_coverage].each do |item|
          if DRI::Metadata::Transformations.dcmi_point? item
            if point_hash[:geocode_point].nil?
              point_hash[:geocode_point] = [item]
            else
              point_hash[:geocode_point] << item
            end
          elsif DRI::Metadata::Transformations.dcmi_box? item
            if box_hash[:geocode_box].nil?
              box_hash[:geocode_box] = [item]
            else
              box_hash[:geocode_box] << item
            end
          end
        end
      end

      # Adding :temporal_coverage_period to properties if :temporal_coverage present
      # for temporal indexing
      if !properties[:temporal_coverage].nil? && !properties[:temporal_coverage].empty?
        properties[:temporal_coverage].each do |item|
          if DRI::Metadata::Transformations.dcmi_period? item
            if period_hash[:temporal_coverage_period].nil?
              period_hash[:temporal_coverage_period] = [item]
            else
              period_hash[:temporal_coverage_period] << item
            end
          end
        end
      end

      properties.merge!(point_hash) { |key, old_value, new_value| old_value } unless point_hash.empty?
      properties.merge!(box_hash) { |key, old_value, new_value| old_value } unless box_hash.empty?
      properties.merge!(period_hash) { |key, old_value, new_value| old_value } unless period_hash.empty?

      super(properties)
    end

    def roles=(roles)
      if descMetadata.class == DRI::Metadata::Documentation
        descMetadata.roles = roles
      end
    end

    def type
      descMetadata.resource_type
    end

    def self.find_or_create(pid)
      begin
        DRI::Documentation.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
        DRI::Documentation.create({pid: pid})
      end
    end

    def to_solr(solr_doc={}, opts={})
      super(solr_doc, opts)
    end

    # Override from interchangeable_metadata: descMetadata doesn't inherit from base and it loads the correct class
    def load_attributes
      @metadata_class = descMetadata.class
    end

    # Override from interchangeable_metadata as DRI::Metadata::Documentation does not inherit from DRI::Metadata::Base
    def custom_validations
      results = descMetadata.custom_validations

      if results.empty?
        return true
      else
        results.each do |key, value|
          errors.add(key,value)
        end
        return false
      end
    end # custom_validations

  end
end
