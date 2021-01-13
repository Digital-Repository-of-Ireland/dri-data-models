# frozen_string_literal: true
require 'valkyrie'
require_relative 'dri_data_models'

Rails.application.config.to_prepare do
    indexer =  Valkyrie::Persistence::Solr::CompositeIndexer.new(
    SystemIndexer,
    AccessControlIndexer,
    DigitalObjectIndexer,
    GenericFileIndexer,
    CollectionIndexer,
    AttachedFilesIndexer,
    ObjectTypesIndexer,
    EadObjectTypesIndexer,
    FileMetadataIndexer,
    DocumentationIndexer,
    RightsIndexer
  )
  # Registers a metadata adapter for storing and indexing resource metadata into Solr
  # (see Valkyrie::Persistence::Solr::MetadataAdapter)
  Valkyrie::MetadataAdapter.register(
      Valkyrie::Persistence::Solr::MetadataAdapter.new(
        connection: ::RSolr.connect({ read_timeout: 120, open_timeout: 120, url: DriDataModels.solr_config[:url] }),
        resource_indexer: indexer
      ),
    :index_solr
  )
end
