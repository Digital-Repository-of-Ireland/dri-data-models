module DRI

  module Metadata

    # An ActiveFedora datastream that interacts with Qualified DC Metadata.

    class QualifiedDublinCore < ActiveFedora::OmDatastream
      attr_accessor :fields
      class_attribute :class_fields
      self.class_fields = []

      # Set OM (Opinionated Metadata) terminology
      def self.load_inherited_terminology
        set_terminology do |t|
          t.root(:path=>"/*") # Selects the root node of the XML document

          # Simple Dublin Core Fields
          t.title(:namespace_prefix=>"dc", :index_as=>[:stored_searchable, :displayable])
          t.rights(:namespace_prefix=>"dc", :index_as=>[:stored_searchable, :displayable])
          t.description(:namespace_prefix=>"dc", :index_as=>[:stored_searchable, :displayable])
          t.language(:namespace_prefix=>"dc", :index_as=>[:stored_searchable, Descriptors.language_facetable])
          t.subject(:namespace_prefix=>"dc", :index_as=>[:stored_searchable, :facetable])
          t.date(:namespace_prefix=>"dc", :index_as=>[:stored_searchable, :dateable])
          t.contributor(:path=>"contributor", :namespace_prefix=>"dc", :index_as=>[:facetable, :stored_searchable])
          t.source(:path=>"source", :namespace_prefix=>"dc", :index_as=>[:displayable])
          t.publisher(:path=>"publisher", :namespace_prefix=>"dc", :index_as=>[:facetable, :stored_searchable, :displayable])
          t.coverage(:namespace_prefix=>"dc", :index_as=>[:stored_searchable, :facetable])
          t.relation(:namespace_prefix=>"dc", :index_as=>[:displayable])
          t.creator(:namespace_prefix=>"dc", :index_as=>[:facetable, :stored_searchable, :displayable])
          t.format(:namespace_prefix=>"dc", :index_as=>[:facetable, :stored_searchable, :displayable])
          t.type(:namespace_prefix=>"dc", :index_as=>[:facetable, :stored_searchable, :displayable])

          # Qualified Dublin Core fields
          t.published_date(:path=>"issued", :namespace_prefix=>"dcterms", :index_as=>[:stored_searchable, :displayable, :dateable])
          t.creation_date(:path=>"created", :namespace_prefix=>"dcterms", :index_as=>[:stored_searchable, :displayable, :dateable])
          t.geographical_coverage(:path=>"spatial", :namespace_prefix=>"dcterms", :index_as=>[:stored_searchable, :facetable, :displayable])
          t.temporal_coverage(:path=>"temporal", :namespace_prefix=>"dcterms", :index_as=>[:stored_searchable, :facetable, :displayable])
          t.geocode_point(:ref=>:geographical_coverage, :attributes=> {"xsi:type"=>"dcterms:Point"}, :index_as=> [:stored_searchable, :displayable])
          t.geocode_box(:ref=>:geographical_coverage, :attributes=> {"xsi:type"=>"dcterms:Box"}, :index_as=> [:stored_searchable, :displayable])

          # Generate MARC Relators fields from the MARC Relators vocabulary
          DRI::Vocabulary::marcRelators.each do |role|
            t.send "role_"+role, :path=>role, :namespace_prefix=>"marcrel", :index_as=>[:facetable, :stored_searchable, :displayable]
          end
        end

      end

      def update_indexed_attributes(params={}, opts={})
        # if the params are just keys, not an array, make then into an array.
        new_params = {}
        params.each do |key, val|
          if key.is_a? Array
            new_params[key] = val
          else
            new_params[[key.to_sym]] = val
          end
        end
        super(new_params, opts)
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
            }
          end
          return builder.doc
      end

      # merge in special facets (e.g. person) into solr document
      def to_solr(solr_doc=Hash.new)
        super(solr_doc)

        # Retrieve list of all people and add them to facet and search indexes in solr document
        person_array = get_person_array()

        solr_doc.merge!(Solrizer.solr_name('person', :facetable) => person_array)
        solr_doc.merge!(Solrizer.solr_name('person', :stored_searchable, type: :text) => person_array | DRI::Metadata::Transformations.transform_name(person_array))
        
        # title_sorted - A SOLR index for sorting titles
        if (title.length > 0)
          sorted_title = DRI::Metadata::Transformations.transform_title_for_sort(title[0])
          if (sorted_title != "")
            solr_doc.merge!(Solrizer.solr_name('title_sorted', :stored_sortable, type: :text) => [sorted_title])
          end
        end

        # all_metadata - A SOLR index of all the text contained in the XML document
        all_metadata = ""
        ng_xml.xpath("//text()").each do |text_node|
          all_metadata += text_node.text
          all_metadata += " "
        end
        solr_doc.merge!(Solrizer.solr_name("all_metadata", :stored_searchable, type: :text) => [all_metadata])

        # Split date ranges into separate indexes
        #date_ranges = Transformations.transform_date_ranges({ "date" => date, "published_date" => published_date, "creation_date" => creation_date})
        #solr_doc.merge!(date_ranges)

        solr_doc
      end

      # Creates an array of all names stored in the metadata
      def get_person_array()
          people = contributor | creator

          DRI::Vocabulary::marcRelators.each do |role|
            people |= send("role_"+role)
          end

          return people
      end

      # Load Dublin Core terminology
      load_inherited_terminology      
    end # class
    
  end # module

end # module
