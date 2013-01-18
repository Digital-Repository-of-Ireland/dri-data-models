#require 'hydra/datastream/common_mods_index_methods'

module DRI

  module Metadata

    # A Fedora Datastream object containing DC Metadata for the descMetadata 
    # datastream in the Audio hydra content type.

    class DublinCoreAudio < ActiveFedora::NokogiriDatastream

      # OM (Opinionated Metadata) terminology mapping for Dublin Core
      set_terminology do |t|
        t.root(:path=>"/*") # Selects the root node of the XML document
        t.title(:namespace_prefix=>"dc", :index_as=>[:searchable, :displayable, :sortable])
        t.rights(:namespace_prefix=>"dc", :index_as=>[:searchable, :displayable])
        t.description(:namespace_prefix=>"dc", :index_as=>[:searchable, :displayable])
        t.language(:namespace_prefix=>"dc", :index_as=>[:searchable, :facetable])
        t.subject(:namespace_prefix=>"dc", :index_as=>[:searchable, :facetable])
        t.date(:namespace_prefix=>"dc", :type=> :date, :index_as=>[:searchable, :displayable])
        t.broadcast_date(:path=>"issued", :namespace_prefix=>"dcterms", :index_as=>[:searchable, :displayable, :facetable])
        t.creation_date(:path=>"created", :namespace_prefix=>"dcterms", :index_as=>[:searchable, :displayable, :facetable])
        t.contributor(:path=>"contributor", :namespace_prefix=>"dc", :index_as=>[:facetable, :searchable])
        t.source(:path=>"source", :namespace_prefix=>"dc", :index_as=>[:displayable])

        t.presenter(:path=>"hst", :namespace_prefix=>"marcrel", :index_as=>[:facetable, :searchable])
        t.producer(:path=>"pro", :namespace_prefix=>"marcrel", :index_as=>[:facetable, :searchable])
        t.guest(:ref=>:contributor, :index_as=>[:facetable])      

        t.coverage(:namespace_prefix=>"dc", :index_as=>[:searchable, :facetable])
        t.geographical_coverage(:path=>"spatial", :namespace_prefix=>"dcterms", :index_as=>[:searchable, :facetable, :displayable])
        t.temporal_coverage(:path=>"temporal", :namespace_prefix=>"dcterms", :index_as=>[:searchable, :facetable, :displayable])

      end # set_terminology

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

      def to_solr(solr_doc=Hash.new)
        super(solr_doc)

        # Merging person fields and creating facet and text indexes for searching/faceting all people
        person_array = contributor | presenter | producer | guest
        solr_doc.merge!(:person_facet => person_array)
        solr_doc.merge!(:person_t => person_array)
        solr_doc
      end

    end # class

  end # module

end # module
