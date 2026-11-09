# frozen_string_literal: true
module DRI
  module Indexing
    extend ActiveSupport::Concern

    included do
      attr_accessor :index_needs_update

      before_create :assign_alternate_id
      after_commit  :update_index, on: [:create, :update], if: :index_needs_update?
      after_commit :delete_from_solr, on: :destroy
    end

    def self.batch_mode?
      Thread.current[:dri_index_batch] == true
    end

    def self.batch
      previous = Thread.current[:dri_index_batch]
      Thread.current[:dri_index_batch] = true
      yield
    ensure
      Thread.current[:dri_index_batch] = previous
    end

    def adapter
      Valkyrie::MetadataAdapter.find(DRI::Indexing.batch_mode? ? :index_solr_batch : :index_solr)
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

    def index_needs_update?
      @index_needs_update.nil? ? true : @index_needs_update
    end

    protected

    def assign_alternate_id
      if !alternate_identifier.alternate_id && (new_id = assign_id)
        alternate_identifier.alternate_id = new_id
      end
    end

    def delete_from_solr
      adapter.persister.connection.delete_by_id(alternate_id, params: { 'softCommit' => true })
    end
  end
end
