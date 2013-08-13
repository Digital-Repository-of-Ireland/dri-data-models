module DRI

  module Metadata

    class EncodedArchivalDescription < ActiveFedora::OmDatastream

      # OM (Opinionated Metadata) terminology mapping for EAD
      set_terminology do |t|
        t.root(:path=>"ead") # Selects the root node of the XML document
        
          t.title(:path=>"archdesc/did/unittitle", :index_as=>[:stored_searchable, :displayable, :sortable])
          t.description(:path=>"archdesc/did/abstract", :index_as=>[:stored_searchable, :displayable])
          t.language(:path=>"archdesc/did/langmaterial", :index_as=>[:stored_searchable, :facetable])
          t.creator(:path=>"archdesc/did/origination", :index_as=>[:stored_searchable, :facetable])
          t.creation_date(:path=>"archdesc/did/unitdate", :index_as=>[:stored_searchable, :displayable, :facetable])
          t.archdesc        
        
          t.subject(:path=>"archdesc//subject", :index_as=>[:stored_searchable, :facetable, :displayable])
          t.persname_coverage(:path=>"archdesc//persname", :index_as=>[:displayable])
          t.name_coverage(:path=>"archdesc//name", :index_as=>[:displayable])
          t.corpname_coverage(:path=>"archdesc//corpname", :index_as=>[:displayable])
          t.geographical_coverage(:path=>"archdesc//geogname", :index_as=>[:stored_searchable, :facetable])
      end # set_terminology

      # Build the xml doc
      def self.xml_template
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.doc.create_internal_subset(
              'ead',
              "+//ISBN 1-931666-00-8//DTD ead.dtd (Encoded Archival Description (EAD) Version 2002)//EN",
              ""
              )
            xml.ead {
              xml.eadheaderxml {
                xml.eadid
                xml.filedesc {
                  xml.titlestmt {
                    xml.titleproper
                  }
                }
              }
              xml.archdesc {
                xml.did
                xml.dsc
              }
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
