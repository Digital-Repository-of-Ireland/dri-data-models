#require 'hydra/datastream/common_mods_index_methods'

module DRI

  module Metadata

    # A Fedora Datastream object containing DC Metadata for the descMetadata 
    # datastream in the Audio hydra content type.

    class DublinCoreAudio < ActiveFedora::NokogiriDatastream

      # OM (Opinionated Metadata) terminology mapping for Dublin Core
      set_terminology do |t|
        t.title(:namespace_prefix=>"dc", :index_as=>[:searchable, :displayable, :sortable])
        t.description(:namespace_prefix=>"dc", :index_as=>[:searchable, :displayable])
        t.language(:namespace_prefix=>"dc", :index_as=>[:searchable, :facetable])
        t.subject(:namespace_prefix=>"dc", :index_as=>[:searchable, :facetable])
        t.date(:namespace_prefix=>"dc", :type=> :date, :index_as=>[:searchable, :displayable])
        t.broadcast_date(:path=>"issued", :namespace_prefix=>"dcterms", :index_as=>[:searchable, :displayable, :facetable])
        t.person(:path=>"contributor", :namespace_prefix=>"dc", :index_as=>[:facetable, :searchable])
        t.source(:path=>"source", :namespace_prefix=>"dc", :index_as=>[:displayable])

        t.presenter(:ref=>:person, :attributes=>{"type" => "presenter"}, :index_as=>[:facetable])
        t.guest(:ref=>:person, :attributes=>{"type" => "guest"}, :index_as=>[:facetable])      
      end # set_terminology

      def self.xml_template
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.qualifieddc(
               "xmlns:dc" => "http://purl.org/dc/elements/1.1/",
               "xmlns:dcterms" => "http://purl.org/dc/terms/",
               "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
               "xsi:noNamespaceSchemaLocation"=>"http://dublincore.org/schemas/xmls/qdc/2008/02/11/qualifieddc.xsd") {
                 xml['dc'].title 
                 xml['dc'].description
	         xml['dc'].type "Sound"
                 xml['dc'].language "en" 
            }
          end
          return builder.doc
      end

    end # class

  end # module

end # module
