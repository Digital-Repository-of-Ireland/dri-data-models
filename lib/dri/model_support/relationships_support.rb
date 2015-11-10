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
            root_key = ActiveFedora::SolrQueryBuilder.solr_name('root_collection_id', :stored_searchable, type: :string)
            # We need to index the identifier element value to be able to search in Solr
            # and then retrieve the document by id
            solr_query = "#{solr_id_field}:\"#{item_id}\""
            solr_query << " AND #{root_key}:\"#{root.first}\""
            solr_results = ActiveFedora::SolrService.query(solr_query, defType: 'edismax')

            if solr_results.empty?
              Rails.logger.error("Relationship target object #{item_id} not found in Solr for object #{id}")
            else
              solr_results.each { |item| records << item['id'] }
            end
          end
        end

        records
      end # end retrieve_relation_records

      def root_collection
        root = nil

        solr_query = "id:\"#{id}\""
        solr_docs = ActiveFedora::SolrService.query(solr_query, rows: 1, defType: 'edismax')

        if solr_docs.nil? || solr_docs.empty?
          Rails.logger.error("Solr document for object #{id} not found in Solr")
        else
          solr_key = ActiveFedora::SolrQueryBuilder.solr_name('root_collection_id', :stored_searchable, type: :string)
          root = solr_docs[0][solr_key]

          if root.nil?
            Rails.logger.error("Root Collection ID for object #{id} not found in Solr")
          end
        end

        root
      end
    end
  end
end
