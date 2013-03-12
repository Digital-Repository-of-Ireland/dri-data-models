#require 'hydra/datastream/common_mods_index_methods'

module DRI

  module Metadata

    # A Fedora Datastream object containing DC Metadata for the descMetadata 
    # datastream in the Audio model.

    class DublinCoreAudio < DRI::Metadata::QualifiedDublinCore

      # Load terminology in QualifiedDublinCore
      load_inherited_terminology

      # Add more mappings for Audio Object
      extend_terminology do |t|
        t.presenter(:path=>"hst", :namespace_prefix=>"marcrel", :index_as=>[:facetable, :searchable])
        t.producer(:path=>"pro", :namespace_prefix=>"marcrel", :index_as=>[:facetable, :searchable])
        t.guest(:ref=>:contributor, :index_as=>[:facetable])
        t.broadcast_date(:ref=>:published_date, :index_as=>[:searchable, :facetable, :displayable])
      end

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
	         xml['dc'].type "Sound"
                 xml['dc'].language "en" 
            }
          end
          return builder.doc
      end

      def get_person_array()
         return contributor | presenter | producer | guest
      end

    end # class

  end # module

end # module
