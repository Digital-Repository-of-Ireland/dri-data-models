module DRI
  module Indexing
    extend ActiveSupport::Concern

    included do
      before_create :assign_noid
      after_save    :update_index
      after_destroy :delete_from_solr
    end

    def adapter
      @adapter ||= Valkyrie::MetadataAdapter.find(:index_solr)
    end

      # Updates Solr index with self.
    def update_index
      adapter.persister.save(resource: self)
    end

    def delete
      super
      delete_from_solr
    end

    def optimistic_locking_enabled?
      false
    end

    def internal_resource
      @internal_resource ||= ['Valkyrie::Resource']
    end

    def internal_resource=(klass)
      @internal_resource = klass
    end

    def optimistic_lock_token=(token)
      @optimistic_lock_token = token
    end

    def new_record
      @new_record ||= persisted?
    end

    def new_record=(is_new)
      @new_record = is_new
    end

    def to_solr
      adapter.resource_indexer.new(resource: self).to_solr
    end

    protected

      def assign_noid
        if !self.noid && new_id = assign_id
          self.noid = new_id
        end
      end

      def delete_from_solr
        adapter.persister.connection.delete_by_id(noid, params: { 'softCommit' => true })
      end
  end
end
