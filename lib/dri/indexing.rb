module DRI
  module Indexing
    extend ActiveSupport::Concern

    #included do
    #  include ActiveFedora::Indexing
    #end
    included do
      class_attribute :indexer, instance_accessor: false
      # This is the default indexer class to use for this model.
      self.indexer = ActiveFedora::IndexingService
    end

    def indexing_service
      @indexing_service ||= self.class.indexer.new(self)
    end

    # Updates Solr index with self.
    def update_index
      ActiveFedora::SolrService.add(to_solr, softCommit: true)
    end

    def _create_record(options = {})
      if !self.noid && new_id = assign_id
        self.noid = new_id
      end
      id = super()
      update_index
    end

    def _update_record(options = {})
      updated = super()
      update_index
    end

    module ClassMethods
      # @return ActiveFedora::Indexing::Map
      def index_config
        @index_config ||= ActiveFedora::Indexing::Map.new
      end
    end
  end
end
