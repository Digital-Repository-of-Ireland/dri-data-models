module DRI
  module ModelSupport
  	module Collections
      extend ActiveSupport::Concern

      included do
      	attr_accessor :collection

        belongs_to :governing_collection, :property=>:is_governed_by, :class_name => 'Batch'
        has_many :governed_items, :property=>:is_governed_by, :class_name => 'Batch'

        has_many :collections, :property=>:is_member_of_collection, :class_name => 'Batch'
        has_many :items, :property=>:is_member_of_collection, :class_name => 'Batch'

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
      	# or using the collection accessor and there are no generic_files attached
      	# to the object.
        descMetadata.is_collection? && (generic_files.count == 0)
      end

      def is_root_collection?
      	# It is a root collection if it is already defined to be a collection, it has
      	# been already saved in Fedora and it has no governing collection
        (!new?) && is_collection? && (governing_collection == nil) && (collections.count == 0)
      end

    end
  end
end