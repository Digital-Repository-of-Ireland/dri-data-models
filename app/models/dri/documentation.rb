module DRI
  class Documentation < ActiveFedora::Base
    include Sufia::ModelMethods
    include Sufia::Noid
    include Sufia::GenericFile::Export
    include DRI::ModelSupport::Properties
    include DRI::ModelSupport::Permissions

    belongs_to :documentation_for, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isDescriptionOf, class_name: "DRI::Batch"

    # It supports all the DRI Compulsory elements
    property :title, predicate: ::RDF::DC.title, multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable
    end

    property :creator, predicate: ::RDF::DC.creator, multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable
    end

    property :description, predicate: ::RDF::DC.description, multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable
    end

    property :rights, predicate: ::RDF::DC.rights, multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable
    end

    property :language, predicate: ::RDF::DC.language, multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable,DRI::Metadata:: Descriptors.language_facetable
    end

    property :created, predicate: ::RDF::DC.created, multiple: true do |index|
      index.as DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable
    end

  end
end