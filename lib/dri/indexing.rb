# frozen_string_literal: true
module DRI
  module Indexing
    extend ActiveSupport::Concern

    included do
      before_create :assign_alternate_id
      after_commit  :update_index, on: [:create, :update]
      after_destroy :delete_from_solr
    end

    def adapter
      @adapter ||= Valkyrie::MetadataAdapter.find(:index_solr)
    end

    # Updates Solr index with self.
    def update_index
      adapter.persister.save(resource: ValkyrieWrapper.new(wrapped_object: self))
    end

    def delete
      super
      delete_from_solr
    end

    def to_solr
      adapter.resource_indexer.new(resource: ValkyrieWrapper.new(wrapped_object: self)).to_solr
    end

    protected

    def assign_alternate_id
      if !self.alternate_id && (new_id = assign_id)
        self.alternate_id = new_id
      end
    end

    def delete_from_solr
      adapter.persister.connection.delete_by_id(alternate_id, params: { 'softCommit' => true })
    end
  end
end
