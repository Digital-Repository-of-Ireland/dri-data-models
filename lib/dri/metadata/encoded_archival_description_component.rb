module DRI

  module Metadata

    class EncodedArchivalDescriptionComponent < ActiveFedora::OmDatastream

      # OM (Opinionated Metadata) terminology mapping to an EAD Component tag
      set_terminology do |t|
        t.root(:path=>"/*", :namespace_prefix => nil) {
          t.ead_level(:path => {:attribute=>"level"})
        }
        t.title(:path=>"unittitle", :index_as=>[:stored_searchable, :displayable, :sortable])
        t.description(:path=>"abstract", :index_as=>[:stored_searchable, :displayable])
        t.language(:path=>"langmaterial", :index_as=>[:stored_searchable, :facetable])
        t.creator(:path=>"origination", , :index_as=>[:stored_searchable, :facetable])
        t.subject(:path=>"subject", :index_as=>[:stored_searchable, :facetable])
        t.name_coverage(:path=>"name", :index_as=>[:stored_searchable, :facetable])
        t.persname_coverage(:path=>"persname", :index_as=>[:stored_searchable, :facetable])
        t.geographical_coverage(:path=>"geogname", :index_as=>[:stored_searchable, :facetable])
        #t.temporal_coverage(:path=>"unittitle", :index_as=>[:stored_searchable, :facetable])
        # EAD doesn't seem to have a tag that can be faceted as temporal_coverage 
        t.creation_date(:path=>"unitdate", :index_as=>[:stored_searchable, :displayable, :facetable], :type=>:date)

        # We need to keep track of the unitid in order to sync this XML snippet to the correct
        # component tag in the complete EAD XML datastream in the collection object!
        t.unitid(:path=>"unitid", :index_as=>[:stored_searchable])
      end # set_terminology

      # Build the xml doc
      def self.xml_template
          builder = Nokogiri::XML::Builder.new do |xml|
              xml.c
            }
          end

          return builder.doc
      end

      def to_solr(solr_doc=Hash.new)
        super(solr_doc)

        # EAD has several "name" tags, so we merge them together into the SOLR document
        person_array = get_person_array()
        solr_doc.merge!(ActiveFedora::SolrService.solr_name('person', :stored_searchable) => person_array)
        solr_doc.merge!(ActiveFedora::SolrService.solr_name('person', :facetable) => person_array)

        solr_doc
      end

      def get_person_array()
         return name_coverage | persname_coverage | corpname_coverage | creator
      end

    end

  end

end
