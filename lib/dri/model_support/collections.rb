module DRI
  module ModelSupport
    module Collections
      extend ActiveSupport::Concern

      included do
      	attr_accessor :collection

        belongs_to :governing_collection, :property=>:is_governed_by, :class_name => 'DRI::Batch'
        has_many :governed_items, :property=>:is_governed_by, :class_name => 'DRI::Batch'

        # Two relationships below are used to manage a collection's structure
        has_many :collections, :property=>:is_member_of_collection, :class_name => 'DRI::Batch'
        has_many :items, :property=>:is_member_of_collection, :class_name => 'DRI::Batch'

        # Additional relationships to keep track of sibling order, important for EAD and similar standards (e.g. MODS)
        belongs_to :previous_sibling, :property=>:is_preceded_by, :class_name => 'DRI::Batch'
        belongs_to :next_sibling, :property=>:is_preceded_by, :class_name => 'DRI::Batch'

        def collection= collection
          if @collection == collection
          	@collection = collection
          elsif (collection == true) && (generic_files.count == 0)
        	  @collection = collection
          elsif (collection == false) && (governed_items.count == 0) && (items.count == 0)
          	@collection = collection
          end
        end

        def collection
          if @collection == true || @collection == false
          	return @collection
          else
          	return false
          end
        end
      end

      def is_collection?
      	# It is a collection if we set it as a collection either through the metadata
      	# or using the collection accessor and it has no GenericFiles
      	# to the object.
        (descMetadata.collection? || properties.collection?) && (generic_files.count == 0)
      end

      def is_root_collection?
      	# It is a root collection if it is already defined to be a collection; it has
      	# been already saved in Fedora; it has no governing collection and
        # it's not a member of any other collection (collection.count == 0)
        (!new_record?) && is_collection? && (governing_collection == nil) && (collections.count == 0)
      end

      private

      #
      # @param[Hash]
      #
      def collections_to_solr(solr_doc=Hash.new)
        # Add title metadata from parent collections
        ancestor_titles = []
        ancestor_ids = []

        curr_gov_collection = governing_collection
        # TODO - Check whether col-to-sub-col rels are kept via 'isGovernedBy' We use isMemberOfCollection as well
        while (curr_gov_collection != nil)
          ancestor_titles << curr_gov_collection.title[0]
          ancestor_ids << curr_gov_collection.pid
          curr_gov_collection = curr_gov_collection.governing_collection
        end

        if (!ancestor_ids.empty?)
          solr_doc.merge!(solr_name('ancestor_title', :facetable) => ancestor_titles)
          solr_doc.merge!(solr_name('ancestor_title', :stored_searchable) => ancestor_titles)
          solr_doc.merge!(solr_name('ancestor_id', :stored_searchable) => ancestor_ids)
          solr_doc.merge!(solr_name('ancestor_id', :facetable) => ancestor_ids)
          solr_doc.merge!(solr_name('governing_id', :facetable) => [ancestor_ids.first]) # needed for user_group gem!!!
          solr_doc.merge!(solr_name('collection_id', :facetable) => [ancestor_ids.first])
          solr_doc.merge!(solr_name('collection_id', :stored_searchable) => [ancestor_ids.first])
          solr_doc.merge!(solr_name('collection', :facetable) => [ancestor_titles.first])
          solr_doc.merge!(solr_name('collection', :stored_searchable) => [ancestor_titles.first])
          solr_doc.merge!(solr_name('root_collection_id', :facetable) => [ancestor_ids.last])
          solr_doc.merge!(solr_name('root_collection_id', :stored_searchable) => [ancestor_ids.last])
          solr_doc.merge!(solr_name('root_collection', :facetable) => [ancestor_titles.last])
          solr_doc.merge!(solr_name('root_collection', :stored_searchable) => [ancestor_titles.last])
        else
          # This must be a root collection
          solr_doc.merge!(solr_name('root_collection', :facetable) => [title.first])
          solr_doc.merge!(solr_name('root_collection', :stored_searchable) => [title.first])
          solr_doc.merge!(solr_name('root_collection_id', :facetable) => [pid])
          solr_doc.merge!(solr_name('root_collection_id', :stored_searchable) => [pid])
        end

        if descMetadata.class == DRI::Metadata::EncodedArchivalDescriptionComponent && previous_sibling == nil
          solr_doc.merge!(solr_name('is_first_sibling', :stored_searchable) => "1")
        end
        
        solr_doc.merge!(solr_name('is_collection', :facetable) => is_collection?)

        solr_doc
      end
    end
  end
end
