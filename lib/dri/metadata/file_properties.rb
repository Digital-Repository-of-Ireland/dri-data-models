module DRI
  module Metadata
    class FileProperties < ActiveFedora::OmDatastream

      # OM (Opinionated Metadata) terminology mapping
      set_terminology do |t|
        t.root(:path=>"properties", :xmlns => '', :namespace_prefix => nil)  # Selects the root node of the XML document
        t.checksum_md5(:namespace_prefix=>nil, :index_as=>[:stored_searchable])
        t.checksum_sha256(:namespace_prefix=>nil, :index_as=>[:stored_searchable])
        t.checksum_rmd160(:namespace_prefix=>nil, :index_as=>[:stored_searchable])
        t.preservation_only(:namespace_prefix=>nil, :index_as=>[:stored_searchable])
      end # set_terminology

      # Build the default XML document
      def self.xml_template
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.properties {
            }
          end
          return builder.doc
      end

    end
  end
end
