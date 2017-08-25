# DRI::Metadata namespace
module DRI::Metadata
  # Implements the descMetadata datastream for DRI::LinkedData digital objects
  class LinkedData < ActiveFedora::NtriplesRDFDatastream
    property :part_of, predicate: RDF::Vocab::DC.isPartOf

    property :resource_type, predicate: RDF::Vocab::DC.type do |index|
      index.as :stored_searchable, :facetable
    end

    property :title, predicate: RDF::Vocab::DC.title do |index|
      index.as :stored_searchable, :facetable
    end

    property :creator, predicate: RDF::Vocab::DC.creator do |index|
      index.as :stored_searchable, :facetable
    end

    property :contributor, predicate: RDF::Vocab::DC.contributor do |index|
      index.as :stored_searchable, :facetable
    end

    property :description, predicate: RDF::Vocab::DC.description do |index|
      index.type :text
      index.as :stored_searchable
    end

    property :tag, predicate: RDF::Vocab::DC.relation do |index|
      index.as :stored_searchable, :facetable
    end

    property :rights, predicate: RDF::Vocab::DC.rights do |index|
      index.as :stored_searchable
    end

    property :publisher, predicate: RDF::Vocab::DC.publisher do |index|
      index.as :stored_searchable, :facetable
    end

    property :date_created, predicate: RDF::Vocab::DC.created do |index|
      index.as :stored_searchable
    end

    property :date_uploaded, predicate: RDF::Vocab::DC.dateSubmitted do |index|
      index.type :date
      index.as :stored_sortable
    end

    property :date_modified, predicate: RDF::Vocab::DC.modified do |index|
      index.type :date
      index.as :stored_sortable
    end

    property :subject, predicate: RDF::Vocab::DC.subject do |index|
      index.as :stored_searchable, :facetable
    end

    property :language, predicate: RDF::Vocab::DC.language do |index|
      index.as :stored_searchable, :facetable
    end

    property :identifier, predicate: RDF::Vocab::DC.identifier do |index|
      index.as :stored_searchable
    end

    property :based_near, predicate: RDF::Vocab::FOAF.based_near do |index|
      index.as :stored_searchable, :facetable
    end

    property :related_url, predicate: RDF::RDFS.seeAlso do |index|
      index.as :stored_searchable
    end

    property :bibliographic_citation, predicate: RDF::Vocab::DC.bibliographicCitation do |index|
      index.as :stored_searchable
    end

    property :source, predicate: RDF::Vocab::DC.source do |index|
      index.as :stored_searchable
    end

    property :spatial, predicate: RDF::Vocab::DC.spatial do |index|
      index.as :stored_searchable
    end

    # Override from ActiveFedora::NtriplesRDFDatastream
    def apply_prefix(name, _file_path)
      "#{name}"
    end
  end
end 
