module DRI
  class Documentation < ActiveFedora::Base
    include Sufia::Noid

    contains "descMetadata", class_name: "DRI::Metadata::Documentation"

    belongs_to :documentation_for, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isDescriptionOf, class_name: "DRI::Batch"

    # Full Simple DC Title, Creator, Subject, Description, Contributor, Publisher, Date, Type,
    # Format, Identifier, Source, Language, Relation, Coverage, Rights
    has_attributes :creator, :title, :subject, :description, :contributor, :publisher, :language,
                   :date, :relation, :source, :geographical_coverage, :temporal_coverage,
                   :type, :format, :coverage, :rights, :identifier, :geocode_point,
                   :geocode_box, datastream: :descMetadata, multiple: true

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

  end
end