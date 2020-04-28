module DRI
  module Indexing
    extend ActiveSupport::Concern

    def conn
      @conn ||= ::RSolr.connect({ read_timeout: 120, open_timeout: 120, url: DriDataModels.solr_config[:url] })
    end

    # Updates Solr index with self.
    def update_index
      conn.add(to_solr, params: { softCommit: true })
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

    # Creates a solr document hash for the {#object}
    # @yield [Hash] yields the solr document
    # @return [Hash] the solr document
    def generate_solr_document
      solr_doc = {}
      Solrizer.set_field(solr_doc, 'system_create', c_time, :stored_sortable)
      Solrizer.set_field(solr_doc, 'system_modified', m_time, :stored_sortable)
      solr_doc['has_model_ssim'] = has_model
      declared_attached_files.each do |name, file|
        solr_doc.merge! file.to_solr(solr_doc, name: name.to_s)
      end
      yield(solr_doc) if block_given?
      solr_doc
    end

    protected

      def c_time
        c_time = create_date.present? ? create_date : DateTime.now
        c_time = DateTime.parse(c_time) unless c_time.is_a?(DateTime)
        c_time
      end

      def m_time
        m_time = modified_date.present? ? modified_date : DateTime.now
        m_time = DateTime.parse(m_time) unless m_time.is_a?(DateTime)
        m_time
      end
  end
end
