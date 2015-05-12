module DRI
  class Documentation < ActiveFedora::Base
    include Sufia::Noid

    has_metadata :name => "descMetadata", :type => DRI::Metadata::Documentation

    belongs_to :documentation_for, property: :is_description_of, :class_name => "DRI::Batch"

    # Full Simple DC Title, Creator, Subject, Description, Contributor, Publisher, Date, Type,
    # Format, Identifier, Source, Language, Relation, Coverage, Rights
    has_attributes :creator, :title, :subject, :description, :contributor, :publisher, :language,
                   :date, :source, :geographical_coverage, :temporal_coverage, :creation_date, :published_date,
                   :resource_type, :format, :coverage, :rights, :identifier,
                   :geocode_point, :geocode_box, :relation, datastream: :descMetadata, multiple: true

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