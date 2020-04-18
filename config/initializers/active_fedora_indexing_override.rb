ActiveFedora::Indexing.module_eval do
  # index the record after it has been persisted to Fedora
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

ActiveFedora::IndexingService.class_eval do
  def c_time
    c_time = object.create_date.present? ? object.create_date : DateTime.now
    c_time = DateTime.parse(c_time.to_s) unless c_time.is_a?(DateTime)
    c_time
  end

  def m_time
    m_time = object.modified_date.present? ? object.modified_date : DateTime.now
    m_time = DateTime.parse(m_time.to_s) unless m_time.is_a?(DateTime)
    m_time
  end
end
