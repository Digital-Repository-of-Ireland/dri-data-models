module DRI

  module Metadata

    # An ActiveFedora datastream that interacts with Qualified DC Metadata.

    class QualifiedDublinCore < ActiveFedora::OmDatastream

      # Set OM (Opinionated Metadata) terminology
      def self.load_inherited_terminology
        set_terminology do |t|
          t.root(:path=>"/*") # Selects the root node of the XML document

          # Simple Dublin Core Fields
          t.title(:namespace_prefix=>"dc", :index_as=>[:stored_searchable, :displayable, :sortable])
          t.rights(:namespace_prefix=>"dc", :index_as=>[:stored_searchable, :displayable])
          t.description(:namespace_prefix=>"dc", :index_as=>[:stored_searchable, :displayable])
          t.language(:namespace_prefix=>"dc", :index_as=>[:stored_searchable, :facetable])
          t.subject(:namespace_prefix=>"dc", :index_as=>[:stored_searchable, :facetable])
          t.date(:namespace_prefix=>"dc", :type=> :date, :index_as=>[:stored_searchable, :displayable])
          t.contributor(:path=>"contributor", :namespace_prefix=>"dc", :index_as=>[:facetable, :stored_searchable])
          t.source(:path=>"source", :namespace_prefix=>"dc", :index_as=>[:displayable])
          t.publisher(:path=>"publisher", :namespace_prefix=>"dc", :index_as=>[:facetable, :stored_searchable, :displayable])
          t.coverage(:namespace_prefix=>"dc", :index_as=>[:stored_searchable, :facetable])
          t.relation(:namespace_prefix=>"dc", :index_as=>[:displayable])
          t.creator(:namespace_prefix=>"dc", :index_as=>[:facetable, :stored_searchable, :displayable])
          t.format(:namespace_prefix=>"dc", :index_as=>[:facetable, :stored_searchable, :displayable])
          t.type(:namespace_prefix=>"dc", :index_as=>[:facetable, :stored_searchable, :displayable])

          # Qualified Dublin Core fields
          t.published_date(:path=>"issued", :namespace_prefix=>"dcterms", :index_as=>[:stored_searchable, :displayable, :facetable])
          t.creation_date(:path=>"created", :namespace_prefix=>"dcterms", :index_as=>[:stored_searchable, :displayable, :facetable])
          t.geographical_coverage(:path=>"spatial", :namespace_prefix=>"dcterms", :index_as=>[:stored_searchable, :facetable, :displayable])
          t.temporal_coverage(:path=>"temporal", :namespace_prefix=>"dcterms", :index_as=>[:stored_searchable, :facetable, :displayable])

          # Placeholder to generate MARC Relators fields
          #DRI::Vocabulary::MarcRelators.each do |role|
          #  t.send("role_"+role,)
          #end

        end

	# Test template for generating a person nodes in Dublin Core
        #define_template :person do |xml, name, role="contributor"|
	#  if (role == "contributor")
	#    xml['dc'].contributor { xml.text name }
        #  elsif (role == "creator")
        #    xml['dc'].creator { xml.text name }
        #  elsif (DRI::Vocabulary:MARCRelators.has_key?role)
        #    xml['marcrel'].send "#{role}_", name
        #  end
        #end
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
        solr_doc.merge!(ActiveFedora::SolrService.solr_name('person', :stored_searchable) => person_array)
        solr_doc.merge!(ActiveFedora::SolrService.solr_name('person', :facetable) => person_array)

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
