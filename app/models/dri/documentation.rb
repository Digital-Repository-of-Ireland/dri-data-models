module DRI
  class Documentation < ActiveFedora::Base
    include Sufia::Noid
    include DRI::ModelSupport::Properties
    include DRI::ModelSupport::Permissions

    # Versionable
    has_many_versions

    contains "descMetadata", class_name: "DRI::Metadata::Documentation"

    # Complete metadata record datastream
    contains "fullMetadata", class_name: "DRI::Metadata::FullMetadata"

    # Documentation has_many generic files through Fcrepo::RelsExt.isConstituentOf (to distinguish from Batch relation)
    has_many :generic_files, class_name: "DRI::GenericFile", as: :documentation

    belongs_to :documentation_for, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isDescriptionOf, class_name: "DRI::Batch"

    # Full Simple DC Title, Creator, Subject, Description, Contributor, Publisher, Date, Type,
    # Format, Identifier, Source, Language, Relation, Coverage, Rights
    has_attributes :creator, :title, :subject, :description, :contributor, :publisher, :language,
                   :date, :source, :geographical_coverage, :temporal_coverage, :temporal_coverage_period, :creation_date, :published_date,
                   :resource_type, :format, :coverage, :rights, :identifier,
                   :geocode_point, :geocode_box, :relation, datastream: :descMetadata, multiple: true

    has_attributes  *(DRI::Vocabulary::marcRelators.map { |s| s.prepend("role_").to_sym}), datastream: :descMetadata,
                    multiple: true

    def attributes=(properties)
      super(properties)
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
