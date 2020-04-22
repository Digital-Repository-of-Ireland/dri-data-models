module DRI
  module Indexing
    extend ActiveSupport::Concern

    included do
      include ActiveFedora::Indexing
    end

    def _create_record(options = {})
      if !self.noid && new_id = assign_id
        self.noid = new_id
      end
      id = super()
      update_index if create_needs_index? && options.fetch(:update_index, true)
      id
    end

    # index the record after it has been updated in Fedora
    def _update_record(options = {})
      updated = super()
      update_index if update_needs_index? && options.fetch(:update_index, true)
      updated
    end
  end
end
