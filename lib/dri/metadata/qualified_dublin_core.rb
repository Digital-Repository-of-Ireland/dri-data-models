module DRI

  module Metadata

    # A Fedora Datastream object containing DC Metadata for the descMetadata 
    # datastream in the Audio hydra content type.

    class QualifiedDublinCore < ActiveFedora::NokogiriDatastream

      # Set OM (Opinionated Metadata) terminology
      def self.load_inherited_terminology
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
          t.publisher(:path=>"publisher", :namespace_prefix=>"dc", :index_as=>[:facetable, :searchable, :displayable])
          t.coverage(:namespace_prefix=>"dc", :index_as=>[:searchable, :facetable])
          t.geographical_coverage(:path=>"spatial", :namespace_prefix=>"dcterms", :index_as=>[:searchable, :facetable, :displayable])
          t.temporal_coverage(:path=>"temporal", :namespace_prefix=>"dcterms", :index_as=>[:searchable, :facetable, :displayable])
        end
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
                 xml['dc'].language "en" 
            }
          end
          return builder.doc
      end

      # merge in special facets (e.g. person) into solr document
      def to_solr(solr_doc=Hash.new)
        super(solr_doc)

        person_array = get_person_array()
        solr_doc.merge!(:person_facet => person_array)
        solr_doc.merge!(:person_t => person_array)

        solr_doc
      end

      def get_person_array()
         return contributor
      end

      # Load Dublin Core terminology
      load_inherited_terminology      
    end # class
    
  end # module

end # module
