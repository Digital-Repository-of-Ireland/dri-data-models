module DRI

  module Metadata

    class Base < ActiveFedora::OmDatastream
      def set_delegates model
      end
      
      def unset_delegates
      	[]
      end

      # Can this metadata type replace another metadata type
      def is_interchangeable?
      	true
      end

      def is_collection?
      	false
      end
    end
  end
end