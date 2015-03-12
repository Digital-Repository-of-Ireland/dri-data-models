module DRI

  module Metadata

    class Base < ActiveFedora::OmDatastream
      # Boolean flag for metadata types like EAD where extracts of the metadata
      # may be stored in other Fedora objects. This allows us to add functions
      # to synchronize the XML between several objects
      attr_accessor :synchronize_metadata_on_save

      def set_attributes model
      end
      
      def unset_attributes
      	[]
      end

      # Can this metadata type replace another metadata type
      def interchangeable?
      	true
      end

      def collection?
      	false
      end

      def custom_validations
        Hash.new
      end

      def metadata_path field
        # Generic check, if metadata class responds to fieldname then that's the path
        if respond_to? field
          [field]
        else
          []
        end
      end

      def remove_null_values solr_doc, field
        [:stored_searchable, :facetable].each do |index_type|
          if solr_doc[ActiveFedora::SolrQueryBuilder.solr_name(field, index_type)].present?
            solr_doc[ActiveFedora::SolrQueryBuilder.solr_name(field, index_type)].delete_if{|v| /^null$/i.match(v)}
          end
        end

        solr_doc
      end

    end
  end
end
