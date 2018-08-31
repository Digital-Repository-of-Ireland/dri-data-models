# DRI namespace
module DRI
  # ModelSupport namespace
  module ModelSupport
    # Implements common methods to handle metadata relationships retrieval
    module RelationshipsSupport
      extend ActiveSupport::Concern

      # Retrieve from Solr the list of PIDs for the fedora objects with the given metadata local identifiers
      #
      # @param rels_array [Array<String>] array of metadata identifiers to query for relationships
      # @param solr_id_field [String] the name of the solr metadata identifier field to query
      # @return [Array<String>] array of Fedora digital object PIDs
      def retrieve_relation_records(rels_array, solr_id_field)
        records = []

        root = root_collection

        unless root.nil?
          rels_array.each do |item_id|
            root_key = Solrizer.solr_name('root_collection_id', :stored_searchable, type: :string)
            # We need to index the identifier element value to be able to search in Solr
            # and then retrieve the document by id
            solr_query = "#{solr_id_field}:\"#{item_id}\""
            solr_query << " AND #{root_key}:\"#{root.first}\""
            solr_results = ActiveFedora::SolrService.query(solr_query, defType: 'edismax')

            if solr_results.empty?
              Rails.logger.error("Relationship target object #{item_id} not found in Solr for object #{noid}")
            else
              solr_results.each { |item| records << item['id'] }
            end
          end
        end

        records
      end # end retrieve_relation_records

      #
      # @return [String] the PID for the root collection parent of the given object
      def root_collection
        root = nil

        solr_query = "id:\"#{noid}\""
        solr_docs = ActiveFedora::SolrService.query(solr_query, rows: 1, defType: 'edismax')

        if solr_docs.nil? || solr_docs.empty?
          Rails.logger.error("Solr document for object #{id} not found in Solr")
        else
          solr_key = Solrizer.solr_name('root_collection_id', :stored_searchable, type: :string)
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
