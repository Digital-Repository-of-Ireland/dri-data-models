module DRI

  module Metadata

    class Base < ActiveFedora::OmDatastream
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