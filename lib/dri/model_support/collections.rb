module DRI
  module ModelSupport
    module Collections
      extend ActiveSupport::Concern

      included do
        attr_accessor :collection

        belongs_to :governing_collection,
                   predicate: ActiveFedora::RDF::ProjectHydra.isGovernedBy,
                   class_name: 'DRI::Batch'
        has_many :governed_items,
                 predicate: ActiveFedora::RDF::ProjectHydra.isGovernedBy,
                 class_name: 'DRI::Batch',
                 as: :governing_collection,
                 dependent: :destroy

        # NOT USED - Two relationships below for managing
        # a collection's collections
        # (!) ONLY FOR COLLECTIONS
        #belongs_to :parent_collection,
        #           predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isMemberOfCollection,
        #           class_name: 'DRI::Batch'
        #has_many :member_collections,
        #         class_name: 'DRI::Batch',
        #         as: :parent_collection

        # Additional relationships to keep track of sibling order
        # used in EAD
        belongs_to :previous_sibling,
                   predicate: DRI::RDFVocabularies::DriRelsVocabulary.isPrecededBy,
                   class_name: 'DRI::Batch'
        has_many :next_sibling,
                 predicate: DRI::RDFVocabularies::DriRelsVocabulary.isPrecededBy,
                 class_name: 'DRI::Batch',
                 as: :previous_sibling

        def collection=(collection)
          if @collection == collection
            @collection = collection
          elsif collection == true && !generic_files.any?
            @collection = collection
          elsif collection == false && !governed_items.any?
            @collection = collection
          end
        end

        def collection
          @collection == true || @collection == false ? @collection : false
        end
      end

      def is_collection?
        # It is a collection if metadata specifies this
        # or using the collection accessor and it has no associated assets
        (descMetadata.collection? || properties.collection?) && !generic_files.any?
      end

      def is_root_collection?
        # It is a root collection if it is already defined to be a collection; it has
        # been already saved in Fedora; it has no governing collection and
        # it's not a member of any other collection (collection.count == 0)
        # FIXME: #1320
        !new_record? && is_collection? && governing_collection.nil?
      end

      private

      #
      # @param[Hash]
      #
      def collections_to_solr(solr_doc = {})
        # Add title metadata from parent collections
        ancestor_titles = []
        ancestor_ids = []

        curr_gov_collection = governing_collection

        until curr_gov_collection.nil?
          ancestor_titles << curr_gov_collection.title[0]
          ancestor_ids << curr_gov_collection.id
          curr_gov_collection = curr_gov_collection.governing_collection
        end

        if ancestor_ids.empty?
          # This must be a root collection
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('root_collection', :facetable) => [title.first])
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('root_collection', :stored_searchable) => [title.first])
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('root_collection_id', :facetable) => [id])
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('root_collection_id', :stored_searchable) => [id])
        else
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('ancestor_title', :facetable) => ancestor_titles)
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('ancestor_title', :stored_searchable) => ancestor_titles)
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('ancestor_id', :stored_searchable) => ancestor_ids)
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('ancestor_id', :facetable) => ancestor_ids)
          # governing_id needed for user_group gem!!!
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('governing_id', :facetable) => [ancestor_ids.first])
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('collection_id', :facetable) => [ancestor_ids.first])
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('collection_id', :stored_searchable) => [ancestor_ids.first])
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('collection', :facetable) => [ancestor_titles.first])
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('collection', :stored_searchable) => [ancestor_titles.first])
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('root_collection_id', :facetable) => [ancestor_ids.last])
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('root_collection_id', :stored_searchable) => [ancestor_ids.last])
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('root_collection', :facetable) => [ancestor_titles.last])
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('root_collection', :stored_searchable) => [ancestor_titles.last])
        end

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('is_collection', :facetable) => is_collection?)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('is_collection', :stored_searchable) => is_collection?)

        solr_doc
      end # collections_to_solr
    end # module
  end # module
end # module
