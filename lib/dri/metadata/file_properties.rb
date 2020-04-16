# DRI namespace
module DRI
  # Metadata namespace
  module Metadata
    # Implements descMetadata DRI properties for DRI Generic Files
    class FileProperties < ActiveFedora::OmDatastream
      # OM (Opinionated Metadata) terminology mapping
      set_terminology do |t|
        # Selects the root node of the XML document
        t.root(path: 'properties', xmlns: '', namespace_prefix: nil)
        t.checksum_md5(namespace_prefix: nil, index_as: [:stored_searchable])
        t.checksum_sha256(namespace_prefix: nil, index_as: [:stored_searchable])
        t.checksum_rmd160(namespace_prefix: nil, index_as: [:stored_searchable])
        t.preservation_only(namespace_prefix: nil, index_as: [:stored_searchable])
      end # set_terminology

      # Build the default XML document
      def self.xml_template
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.properties {
            }
          end
          return builder.doc
      end

      def prefix(path)
        return ''
      end
    end
  end
end
