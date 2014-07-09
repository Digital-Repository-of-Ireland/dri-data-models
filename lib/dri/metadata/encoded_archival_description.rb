module DRI

  module Metadata

    class EncodedArchivalDescription < DRI::Metadata::Base

      # OM (Opinionated Metadata) terminology mapping to an EAD Collection
      set_terminology do |t|
        t.root(:path=>"*", :namespace_prefix => nil)

        t.ead(:path=>"*", :namespace_prefix => nil) {
          t.eadheader {
            # We need to keep track of the unitid in order to sync this XML snippet to the correct
            # component tag in the complete EAD XML datastream in the collection object!
            t.eadid(:path=>"eadid", :namespace_prefix => nil) {
              t.repository_code(:path => {:attribute=>"mainagencycode"}, :namespace_prefix => nil)
              t.country_code(:path => {:attribute=>"countrycode"}, :namespace_prefix => nil)
              t.identifier(:path => {:attribute=>"identifier"}, :namespace_prefix => nil)
            }
            t.filedesc {
              t.titlestmt {
                t.title(:path=>"titleproper")
              }
            }
          }  
          t.archdesc {
             t.subject(:path=>"subject")
              t.name_coverage(:path=>"name")
              t.persname_coverage(:path=>"persname")
              t.corpname_coverage(:path=>"corpname")
              t.geographical_coverage(:path=>"geogname")
            t.ead_level(:path => {:attribute=>"level"}, :namespace_prefix => nil)
            t.did(:path => "did", :namespace_prefix => nil) {
              t.abstract()
              t.language(:path=>"langmaterial")
              t.creator(:path=>"origination")
             
              t.creation_date(:path=>"unitdate") {
                t.normal(:path => {:attribute=>"normal"}, :namespace_prefix => nil)
                t.datechar(:path => {:attribute=>"datechar"}, :namespace_prefix => nil)
              }
              t.physdesc(:path=>"physdesc") {
                t.type(:path=>"genreform")
              }
              t.dao(:path=>"dao") {
                t.href(:path => {:attribute=>"href"}, :namespace_prefix => nil)
              }
            }
            t.bioghist {

            }
            t.scopecontent {

            }
          }
        }
        t.ead_level(:proxy => [:ead, :archdesc, :ead_level])
        t.unitid(:proxy => [:ead, :eadheader, :eadid], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.repository_code(:proxy => [:ead, :eadheader, :eadid, :repository_code], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.country_code(:proxy => [:ead, :eadheader, :eadid, :country_code], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.identifier(:proxy => [:ead, :eadheader, :eadid, :identifier], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.title(:proxy => [:ead, :eadheader, :filedesc, :titlestmt, :title], :index_as=>[Descriptors.cleaned_searchable, :sortable])
        t.abstract(:proxy => [:ead, :archdesc, :did,  :abstract], :index_as=>[Descriptors.cleaned_searchable])
        t.creation_date(:proxy => [:ead, :archdesc, :did, :creation_date], :index_as=>[Descriptors.cleaned_searchable])
        t.language(:proxy => [:ead, :archdesc, :did, :language], :index_as=>[Descriptors.cleaned_searchable,  Descriptors.language_facetable])
        t.creator(:proxy => [:ead, :archdesc, :did, :creator], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.scope_content(:proxy => [:ead, :archdesc, :scopecontent], :index_as=>[Descriptors.cleaned_searchable])
        t.subject(:proxy => [:ead, :archdesc, :subject], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.name_coverage(:proxy => [:ead, :archdesc,  :name_coverage], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.persname_coverage(:proxy => [:ead, :archdesc, :persname_coverage], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.corpname_coverage(:proxy => [:ead, :archdesc, :corpname_coverage], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.geographical_coverage(:proxy => [:ead, :archdesc,  :geographical_coverage], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.physdesc(:proxy => [:ead, :archdesc, :did, :physdesc], :index_as=>[Descriptors.cleaned_searchable])
        t.type(:proxy => [:ead, :archdesc, :did, :physdesc, :type], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.bioghist(:proxy => [:ead, :archdesc, :bioghist], :index_as=>[Descriptors.cleaned_searchable])
  
      end # set_terminology

      def synchronize_metadata_on_save
        @synchronize_metadata_on_save || true
      end

      # Build the xml doc
      def self.xml_template
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.doc.create_internal_subset(
              'ead',
              "+//ISBN 1-931666-00-8//DTD ead.dtd (Encoded Archival Description (EAD) Version 2002)//EN",
              ""
              )
            xml.ead {
              xml.eadheader {
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
        solr_doc = super(solr_doc)

        # EAD has several "name" tags, so we merge them together into the SOLR document
        person_array = get_person_array()
        solr_doc.merge!(ActiveFedora::SolrService.solr_name('person', :stored_searchable) => person_array)
        solr_doc.merge!(ActiveFedora::SolrService.solr_name('person', :facetable) => person_array)
        solr_doc.merge!(ActiveFedora::SolrService.solr_name('description', :searchable) => description)

        solr_doc
      end


      def get_person_array()
         return ead.archdesc.name_coverage | ead.archdesc.persname_coverage | ead.archdesc.corpname_coverage | ead.archdesc.did.creator
      end

      def description
        return ead.archdesc.did.abstract | ead.archdesc.scopecontent | ead.archdesc.bioghist
      end

      def metadata_path field
        case field
        when :ead_level
          [:ead, :archdesc, :ead_level]
        when :title
          [:ead, :eadheader, :filedesc, :titlestmt, :title]
        when :abstract
          [:ead, :archdesc, :did, :abstract]
        when :bioghist
          [:ead, :archdesc, :bioghist]
        when :scope_content
          [:ead, :archdesc, :scopecontent]
        when :ead_level
          [:ead, :archdesc, :ead_level]
        when :language
          [:ead, :archdesc, :did, :language]
        when :creator
          [:ead, :archdesc, :did, :creator]
        when :creation_date
          [:ead, :archdesc, :did, :creation_date]
        when :name_coverage
          [:ead, :archdesc,  :name_coverage]
        when :geographical_coverage
          [:ead, :archdesc, :geographical_coverage]
        when :physdesc
          [:ead, :archdesc, :did, :physdesc]
        when :type
          [:ead, :archdesc, :did, :physdesc, :type]
        when :dao
          [:ead, :archdesc, :did, :dao]
        when :unitid
          [:ead, :eadheader, :eadid]
        when :repository_code
          [:ead, :eadheader, :eadid, :repository_code]
        when :country_code
          [:ead, :eadheader, :eadid, :country_code]
        when :identifier
          [:ead, :eadheader, :eadid, :identifier]
        else
          []
        end
      end

      def interchangeable?
        false
      end

      def collection?
        true
      end

      def custom_validations
        errors = Hash.new

        title_result = false
        description_result = false
        unitid_result = false
        cc_result = false
        rc_result = false
        ead_level_result = false

        ead.eadheader.filedesc.titlestmt.title.each do |curr_title|
          title_result = true unless curr_title.blank?
        end

        description.each do |curr_description|
          description_result = true unless curr_description.blank?
        end

        ead.archdesc.ead_level.each do |curr_ead_level|
          ead_level_result = true unless curr_ead_level.blank?
        end

        ead.eadheader.eadid.each do |curr_unitid|
          unitid_result = true unless curr_unitid.blank?
        end

        ead.eadheader.eadid.country_code.each do |curr_cc|
          cc_result = true unless curr_cc.blank?
        end

        ead.eadheader.eadid.repository_code.each do |curr_rc|
          rc_result = true unless curr_rc.blank?
        end
        
        errors[:title] = "can't be blank" if title_result == false
        errors[:abstract] = "can't be blank" if description_result == false
        errors[:ead_level] = "can't be blank" if ead_level_result == false
        errors[:unitid] = "can't be blank" if unitid_result == false
        errors[:country_code] = "can't be blank" if cc_result == false
        errors[:repository_code] = "can't be blank" if rc_result == false

        errors
      end

    end

  end

end
