module DRI

  module Metadata

class CollectionMetadata < ActiveFedora::NokogiriDatastream

      # OM (Opinionated Metadata) terminology mapping for Dublin Core
      set_terminology do |t|
        t.root(:path=>"/*") # Selects the root node of the XML document
        t.title(:namespace_prefix=>"dc", :index_as=>[:searchable, :displayable, :sortable])
        t.description(:namespace_prefix=>"dc", :index_as=>[:searchable, :displayable])
        t.creator(:namespace_prefix=>"dc", :index_as=>[:searchable, :displayable])
        t.part(:namespace_prefix=>"dc", :index_as=>[:searchable])
      end # set_terminology

      # Build the xml doc
      def self.xml_template
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.qualifieddc(
               "xmlns:dc" => "http://purl.org/dc/elements/1.1/",
               "xmlns:dcterms" => "http://purl.org/dc/terms/",
               "xmlns:marcrel" => "http://www.loc.gov/marc.relators/",
               "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
               "xsi:schemaLocation" => "http://www.loc.gov/marc.relators/ http://imlsdcc2.grainger.illinois.edu/registry/marcrel.xsd",
               "xsi:noNamespaceSchemaLocation"=>"http://dublincore.org/schemas/xmls/qdc/2008/02/11/qualifieddc.xsd") {
                 xml['dc'].title
                 xml['dc'].description
                 xml['dc'].type "Collection"
            }
          end
          return builder.doc
      end

end

end
end
