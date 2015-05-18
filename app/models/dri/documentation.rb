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
      # When updating from DRI form, type attribute key needs to be replaced with resource_type
      properties.keys.each do |k|
        if(k == "type")
          properties["resource_type"] = properties[k]
          properties.delete(k)
        end
      end
      super(properties)
    end

    def type
      descMetadata.resource_type
    end

    def self.find_or_create(pid)
      begin
        DRI::Documentation.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
        DRI::Documentation.create({id: pid})
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
