# DRI namespace
module DRI
  # Metdata namespace
  module Metadata
    # Implements a descMetadata datastream included all extracted metadata
    # extends from AF OnDatastream
    class Extracted < ::DRI::Datastreams::OmDatastream
      # OM (Opinionated Metadata) terminology mapping
      set_terminology do |t|
        t.root(path: "extracted", xmlns: '', namespace_prefix: nil) # Selects the root node of the XML document
        t.full_text(namespace_prefix: nil)
      end # set_terminology

      # Build the default XML document
      def self.xml_template
        Nokogiri::XML.parse("<extracted/>")
      end
    end
  end
end
