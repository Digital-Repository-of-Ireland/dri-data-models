ActiveFedora::Indexing.module_eval do
    # index the record after it has been persisted to Fedora
    def _create_record(options = {})
      if !self.noid && new_id = assign_id
        self.noid = new_id
      end
      super()
      update_index if create_needs_index? && options.fetch(:update_index, true)
      true
    end

    # index the record after it has been updated in Fedora
    def _update_record(options = {})
      super()
      update_index if update_needs_index? && options.fetch(:update_index, true)
      true
    end
end
