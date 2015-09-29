module DRI
  module ModelSupport
    module RelationshipsSupport
      extend ActiveSupport::Concern

      #
      #
      def retrieve_relation_records(rels_array, solr_id_field)
        records = []

        root = root_collection

        unless root.nil?
          rels_array.each do |item_id|
            # We need to index the identifier element value to be able to search in Solr and then retrieve the document by id
            solr_query = "#{solr_id_field}:\"#{item_id.to_s}\""
            solr_query << " AND #{ActiveFedora::SolrQueryBuilder.solr_name('root_collection_id', :stored_searchable, type: :string)}:\"#{root.first.to_s}\""
            solr_results = ActiveFedora::SolrService.query(solr_query, :defType => 'edismax')

            if solr_results.empty?
              Rails.logger.error("Relationship target object #{item_id} not found in Solr for object #{self.id}")
            else
              solr_results.each { |item| records << item['id'] }
            end
          end
        end

        records
      end # end retrieve_relation_records

      def root_collection
        root = nil

        solr_query = "id:\"#{self.id.to_s}\""
        # The query service returns back a set of Solr Documents, therefore need to be casted later on
        solr_docs = ActiveFedora::SolrService.query(solr_query, :rows => 1, :defType => 'edismax')

        if solr_docs.nil? || solr_docs.empty?
          Rails.logger.error("Solr document for object with PID #{self.id} not found in Solr")
        else
          root = solr_docs[0][ActiveFedora::SolrQueryBuilder.solr_name('root_collection_id', :stored_searchable, type: :string)]

          if (root.nil?)
            Rails.logger.error("Root collection ID for object with PID #{self.id} not found in Solr")
          end
        end

        root
      end
    end
  end
end
