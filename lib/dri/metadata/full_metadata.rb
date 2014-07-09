module DRI

  module Metadata

    class FullMetadata < ActiveFedora::OmDatastream

      def prefix
        '' # add a prefix for solr index terms if you need to namespace identical terms in multiple data streams 
      end

    end

  end

end
