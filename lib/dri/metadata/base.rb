module DRI

  module Metadata

    class Base < ActiveFedora::OmDatastream
      # Boolean flag for metadata types like EAD where extracts of the metadata
      # may be stored in other Fedora objects. This allows us to add functions
      # to synchronize the XML between several objects
      attr_accessor :synchronize_metadata_on_save

      # Overwrite this function to add synchronizing logic relevant to
      # your metadata standard
      def synchronize_metadata parent
      end

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
    end
  end
end