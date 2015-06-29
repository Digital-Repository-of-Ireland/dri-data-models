module DRI
  class Documentation < DRI::Batch

    # Override interchangeable_metadata definition of descMetadata
    contains "descMetadata", class_name: "DRI::Metadata::Documentation"

    belongs_to :documentation_for, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isDescriptionOf, class_name: "DRI::Batch"

    # Full Simple DC Title, Creator, Subject, Description, Contributor, Publisher, Date, Type,
    # Format, Identifier, Source, Language, Relation, Coverage, Rights
    #has_attributes :creator, :title, :subject, :description, :contributor, :publisher, :language,
    #               :date, :source, :geographical_coverage, :temporal_coverage, :temporal_coverage_period, :creation_date, :published_date,
    #               :resource_type, :format, :coverage, :rights, :identifier,
    #               :geocode_point, :geocode_box, :relation, datastream: :descMetadata, multiple: true

    has_attributes :date, :source, :geographical_coverage, :temporal_coverage, :temporal_coverage_period,
                   :resource_type, :format, :coverage, :identifier, :geocode_point, :geocode_box, :relation,
                   datastream: :descMetadata, multiple: true

    has_attributes  *(DRI::Vocabulary::marcRelators.map { |s| s.prepend("role_").to_sym}), datastream: :descMetadata,
                    multiple: true

    def attributes=(properties)
      point_hash = Hash.new
      box_hash = Hash.new
      period_hash = Hash.new

      # When updating from DRI form, type attribute key needs to be replaced with resource_type
      properties.keys.each do |k|
        if(k.to_sym == :type)
          properties[:resource_type] = properties[k]
          properties.delete(k)
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

    def roles= roles
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
