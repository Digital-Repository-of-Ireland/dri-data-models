module DRI

  module Metadata

    class Base < ActiveFedora::OmDatastream

      # Boolean flag for metadata types like EAD where extracts of the metadata
      # may be stored in other Fedora objects. This allows us to add functions
      # to synchronize the XML between several objects
      attr_accessor :synchronize_metadata_on_save

      around_save :synchronize_if_changed

      # By default, @synchronize_metadata_on_save is disabled
      def initialize
        super
        @synchronize_metadata_on_save = false
      end

      def synchronize_if_changed
        if (synchronize_metadata_on_save == true)
          content_changed = self.descMetadata.changed?
          yield
          Sufia.queue.push(SynchronizeMetadata.new(self.pid)) if content_changed
        end
      end

      # Overwrite this function to add syncronizing logic relevant to
      # your metadata standard
      def synchronize_metadata
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