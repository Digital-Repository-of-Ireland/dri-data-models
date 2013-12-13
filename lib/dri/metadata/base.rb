module DRI

  module Metadata

    class Base < ActiveFedora::OmDatastream
      # Boolean flag for metadata types like EAD where extracts of the metadata
      # may be stored in other Fedora objects. This allows us to add functions
      # to synchronize the XML between several objects
      attr_accessor :synchronize_metadata_on_save

      # By default, @synchronize_metadata_on_save is disabled
      def initialize(digital_object = nil, dsid = nil, options = {})
        @synchronize_metadata_on_save = false

        super
      end

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
    end
  end
end