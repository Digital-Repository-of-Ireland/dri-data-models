# DRI namespace
module DRI
  # ModelSupport namespace
  module ModelSupport
    # Includes AF properties, collection management methods that are common to all the DRI digital object classes
    module Collections
      extend ActiveSupport::Concern

      included do
        # Flag to determine whether the digital object is a collection
        attr_accessor :collection

        # one-to-one AF association to associate the parent of the given object
        belongs_to :governing_collection, class_name: 'DRI::DigitalObject'
        # one-to-many AF association to associate the children of the given object
        has_many :governed_items,
                 class_name: 'DRI::DigitalObject',
                 as: :governing_collection,
                 dependent: :destroy

        # Additional relationships to keep track of sibling order
        # used in EAD
        # one-to-one AF association to associate the preceding EAD child component for the given object
        belongs_to :previous_sibling, class_name: 'DRI::DigitalObject'
        # one-to-many AF association to associate the succeeding EAD children component for the given object
        has_many :next_sibling, class_name: 'DRI::DigitalObject', as: :previous_sibling

        # Collection flag attribute setter
        #
        def collection=(collection)
          if @collection == collection
            @collection = collection
          elsif collection == true && !generic_files.any? # NO digital assets associated
            @collection = collection
          elsif collection == false && !governed_items.any? # NO digital object children
            @collection = collection
          end
        end

        # Collection flag getter
        def collection
          # if @collection not set, then default to false
          (@collection == true || @collection == false) ? @collection : false
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
        # been already saved in Fedora; it has no governing collection and
        # it's not a member of any other collection (collection.count == 0)
        # FIXME: #1320
        !new_record? && collection? && governing_collection.nil?
      end

      private

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
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('root_collection', :facetable) => [title.first])
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('root_collection', :stored_searchable) => [title.first])
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('root_collection_id', :facetable) => [id])
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('root_collection_id', :stored_searchable) => [id])
        else
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('ancestor_title', :facetable) => ancestor_titles)
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('ancestor_title', :stored_searchable) => ancestor_titles)
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('ancestor_id', :stored_searchable) => ancestor_ids)
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable) => ancestor_ids)
          # governing_id needed for user_group gem!!!
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('governing_id', :facetable) => [ancestor_ids.first])
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('collection_id', :facetable) => [ancestor_ids.first])
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('collection_id', :stored_searchable) => [ancestor_ids.first])
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('collection', :facetable) => [ancestor_titles.first])
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('collection', :stored_searchable) => [ancestor_titles.first])
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('root_collection_id', :facetable) => [ancestor_ids.last])
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('root_collection_id', :stored_searchable) => [ancestor_ids.last])
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('root_collection', :facetable) => [ancestor_titles.last])
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('root_collection', :stored_searchable) => [ancestor_titles.last])
        end

        unless governing_collection.nil?
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name(ActiveFedora::RDF::ProjectHydra.isGovernedBy.fragment, :symbol) => [governing_collection.id])
        end

        if governed_items.present?
          ids = []
          governed_items.each { |item| ids << item.id }
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name(ActiveFedora::RDF::ProjectHydra.isGovernedBy.fragment, :symbol) => ids)
        end

        if previous_sibling
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name(DRI::RDFVocabularies::DriRelsVocabulary.isPrecededBy.fragment, :symbol) => [previous_sibling.id])
        end

        if next_sibling.present?
          ids = []
          next_sibling.each { |item| ids << item.id }
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name(DRI::RDFVocabularies::DriRelsVocabulary.isPrecededBy.fragment, :symbol) => ids)
        end

        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('is_collection', :facetable) => collection?)
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('is_collection', :stored_searchable) => collection?)

        solr_doc
      end # collections_to_solr
    end # module
  end # module
end # module
