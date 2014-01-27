module DRI
  module ModelSupport
  	module Collections
      extend ActiveSupport::Concern

      included do
      	attr_accessor :collection

        belongs_to :governing_collection, :property=>:is_governed_by, :class_name => 'Batch'
        has_many :governed_items, :property=>:is_governed_by, :inbound => true, :class_name => 'Batch'

        has_many :collections, :property=>:is_member_of_collection, :class_name => 'Batch'
        has_many :items, :property=>:is_member_of_collection, :inbound => true, :class_name => 'Batch'

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
      	# It is a root collection if it is already defined to be a collection, it has
      	# been already saved in Fedora and it has no governing collection
        (!new?) && is_collection? && (governing_collection == nil) && (collections.count == 0)
      end

      private

      def collections_to_solr(solr_doc=Hash.new)

        # Add title metadata from parent collections
        collection_titles = []
        collection_id = []

        if (governing_collection != nil)
          collection_titles = [governing_collection.title[0]]
          collection_id = [governing_collection.pid]
        end

        collections.each do |coll|
          collection_titles | coll.title
        end

        if (!collection_titles.empty?)
          solr_doc.merge!(solr_name('collection', :facetable) => collection_titles)
          solr_doc.merge!(solr_name('collection', :stored_searchable) => collection_titles)
          solr_doc.merge!(solr_name('governing_id', :facetable) => collection_id)
        end
        
        solr_doc.merge!(solr_name('is_collection', :facetable) => is_collection?)

        solr_doc
      end

    end
  end
end