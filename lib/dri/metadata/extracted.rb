module DRI
  module Metadata
    class Extracted < ActiveFedora::OmDatastream

      # OM (Opinionated Metadata) terminology mapping
      set_terminology do |t|
        t.root(:path=>"extracted", :xmlns => '', :namespace_prefix => nil)  # Selects the root node of the XML document
        t.full_text(:namespace_prefix=>nil)
      end # set_terminology

      # Build the default XML document
      def self.xml_template
        Nokogiri::XML.parse("<extracted/>")
      end

      def prefix
        '' # add a prefix for solr index terms if you need to namespace identical terms in multiple data streams 
      end
    end
  end
end
