module DRI::Metadata
  class Documentation < ActiveFedora::NtriplesRDFDatastream

    # It supports all the DRI Compulsory elements
    property :title, predicate: RDF::DC.title, multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable,
               DRI::Metadata::Descriptors.cleaned_displayable
    end

    property :identifier, predicate: RDF::DC.identifier do |index|
      index.as :stored_searchable
    end

    property :creator, predicate: RDF::DC.creator, multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable,
               DRI::Metadata::Descriptors.cleaned_displayable,
               :sortable
    end

    property :contributor, predicate: RDF::DC.contributor, multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable,
               DRI::Metadata::Descriptors.cleaned_facetable
    end

    property :publisher, predicate: RDF::DC.publisher, multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_facetable,
               DRI::Metadata::Descriptors.cleaned_searchable,
               DRI::Metadata::Descriptors.cleaned_displayable
    end

    property :description, predicate: RDF::DC.description, multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable,
               DRI::Metadata::Descriptors.cleaned_displayable
    end

    property :rights, predicate: RDF::DC.rights, multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable,
               DRI::Metadata::Descriptors.cleaned_displayable
    end

    property :language, predicate: RDF::DC.language, multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable,
               DRI::Metadata:: Descriptors.language_facetable
    end

    property :date, predicate: RDF::DC.date, multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable,
               DRI::Metadata::Descriptors.cleaned_displayable
    end

    property :creation_date, predicate: RDF::DC.created, multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable,
               DRI::Metadata::Descriptors.cleaned_displayable
    end

    property :published_date, predicate: RDF::DC.issued, multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable,
               DRI::Metadata::Descriptors.cleaned_displayable
    end

    property :subject, predicate: RDF::DC.subject, multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable,
               DRI::Metadata::Descriptors.cleaned_facetable,
               DRI::Metadata::Descriptors.cleaned_displayable
    end

    property :resource_type, predicate: RDF::DC.type do |index|
      index.as DRI::Metadata::Descriptors.cleaned_facetable,
               DRI::Metadata::Descriptors.cleaned_searchable,
               DRI::Metadata::Descriptors.cleaned_displayable
    end

    property :format, predicate: RDF::DC.format do |index|
      index.as DRI::Metadata::Descriptors.cleaned_facetable,
               DRI::Metadata::Descriptors.cleaned_searchable,
               DRI::Metadata::Descriptors.cleaned_displayable
    end

    property :source, predicate: RDF::DC.source do |index|
      index.as DRI::Metadata::Descriptors.cleaned_displayable,
               DRI::Metadata::Descriptors.cleaned_facetable
    end

    property :coverage, predicate: RDF::DC.coverage do |index|
      index.as DRI::Metadata::Descriptors.cleaned_displayable,
               DRI::Metadata::Descriptors.cleaned_searchable
    end

    property :geographical_coverage, predicate: RDF::DC.spatial do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable,
               DRI::Metadata::Descriptors.cleaned_facetable,
               DRI::Metadata::Descriptors.cleaned_displayable
    end

    property :temporal_coverage, predicate: RDF::DC.temporal do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable,
               DRI::Metadata::Descriptors.cleaned_displayable
    end

    property :geocode_point, predicate: RDF::DC.spatial, attributes: {"xsi:type" => RDF::DC.Point} do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable,
               DRI::Metadata::Descriptors.cleaned_displayable
    end

    property :geocode_box, predicate: RDF::DC.spatial, attributes: {"xsi:type" => RDF::DC.Box} do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable,
               DRI::Metadata::Descriptors.cleaned_displayable
    end

    property :relation, predicate: RDF::DC.relation do |index|
      index.as :stored_searchable, :facetable
    end

    def apply_prefix(name, file_path)
      "#{name}"
    end
  end
end