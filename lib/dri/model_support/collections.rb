# frozen_string_literal: true
# DRI namespace
module DRI
  # ModelSupport namespace
  module ModelSupport
    # Includes properties, collection management methods that are common to all the DRI digital object classes
    module Collections
      extend ActiveSupport::Concern

      included do
        # Flag to determine whether the digital object is a collection
        attr_accessor :collection

        # one-to-one AF association to associate the parent of the given object
        belongs_to :governing_collection,
                   class_name: 'DRI::DigitalObject',
                   polymorphic: true,
                   optional: true,
                   autosave: true
        # one-to-many AF association to associate the children of the given object
        has_many :governed_items,
                 class_name: 'DRI::DigitalObject',
                 as: :governing_collection,
                 dependent: :destroy,
                 autosave: true

        has_many :collection_relationships
        has_many :collection_relatives, through: :collection_relationships
        has_many :inverse_collection_relationships, class_name: 'DRI::CollectionRelationship', foreign_key: "collection_relative_id"
        has_many :inverse_collection_relatives, through: :inverse_collection_relationships, source: :digital_object

        # Additional relationships to keep track of sibling order
        # used in EAD
        # one-to-one AF association to associate the preceding EAD child component for the given object
        belongs_to :previous_sibling, class_name: 'DRI::DigitalObject', polymorphic: true, optional: true
        # one-to-many AF association to associate the succeeding EAD children component for the given object
        has_many :next_sibling, class_name: 'DRI::DigitalObject', as: :previous_sibling

        # Collection flag attribute setter
        #
        def collection=(collection)
          return if @collection == collection

          if collection == true && !generic_files.any? # NO digital assets associated
            @collection = collection
          elsif collection == false && !governed_items.any? # NO digital object children
            @collection = collection
          end
        end

        # Collection flag getter
        def collection
          # if @collection not set, then default to false
          @collection ||= false
        end
      end

      # Determine whether the digital object is a collection
      # @return [Boolean] true if collection; false otherwise
      def collection?
        # It is a collection if metadata specifies this
        # or using the collection accessor and it has no associated assets
        (descMetadata.collection? || collection?) && !generic_files.any?
      end

      # Determine whether the digital object is a root, container collection
      # @return [Boolean] true if rootcollection; false otherwise
      def root_collection?
        # It is a root collection if it is already defined to be a collection; it has
        # been already saved; it has no governing collection and
        # it's not a member of any other collection (collection.count == 0)
        !new_record? && collection? && governing_collection.nil?
      end
    end # module
  end # module
end # module
