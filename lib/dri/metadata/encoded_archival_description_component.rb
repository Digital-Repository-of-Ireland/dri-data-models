module DRI

  module Metadata

    class EncodedArchivalDescriptionComponent < DRI::Metadata::Base

      # OM (Opinionated Metadata) terminology mapping to an EAD Component tag
      set_terminology do |t|
        t.root(:path=>"*", :namespace_prefix => nil)

        t.c(:path=>"*", :namespace_prefix => nil) {
          t.ead_level(:path => {:attribute=>"level"}, :namespace_prefix => nil)
          t.archdesc{
            t.subject(:path=>"subject")
            t.name_coverage(:path=>"name")
            t.persname_coverage(:path=>"persname")
            t.corpname_coverage(:path=>"corpname")
            t.geographical_coverage(:path=>"geogname")
          }
          t.did {
            t.unittitle
            t.abstract
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

            # We need to keep track of the unitid in order to sync this XML snippet to the correct
            # component tag in the complete EAD XML datastream in the collection object!
            t.unitid(:path=>"unitid") {
              t.repository_code(:path => {:attribute=>"repositorycode"}, :namespace_prefix => nil)
              t.country_code(:path => {:attribute=>"countrycode"}, :namespace_prefix => nil)
              t.identifier(:path => {:attribute=>"identifier"}, :namespace_prefix => nil)
            }
          }
          t.bioghist {

          }
          t.scopecontent {

          }
        }
        t.ead_level(:proxy => [:c, :ead_level])
        t.title(:proxy => [:c, :did, :unittitle], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable, :sortable])
        t.abstract(:proxy => [:c, :did, :abstract], :index_as=>[Descriptors.cleaned_searchable])
        t.bioghist(:proxy => [:c, :bioghist], :index_as=>[Descriptors.cleaned_searchable])
        t.scope_content(:proxy => [:c, :scopecontent], :index_as=>[Descriptors.cleaned_searchable])
        t.language(:proxy => [:c, :did, :language], :index_as=>[:stored_searchable, Descriptors.language_facetable])
        t.creator(:proxy => [:c, :did, :creator], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.subject(:proxy => [:c, :archdesc, :subject], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.name_coverage(:proxy => [:c, :archdesc, :name_coverage], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.persname_coverage(:proxy => [:c, :archdesc, :persname_coverage], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.corpname_coverage(:proxy => [:c, :archdesc, :corpname_coverage], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.geographical_coverage(:proxy => [:c, :archdesc, :geographical_coverage], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.creation_date(:proxy => [:c, :did, :creation_date], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable, Descriptors.language_facetable])
        t.physdesc(:proxy => [:c, :did, :physdesc], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.type(:ref => [:c, :did, :physdesc, :type], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable, Descriptors.language_facetable])
        t.dao(:proxy => [:c, :did, :dao])
        t.dao_href(:proxy => [:c, :did, :dao, :href])
        t.unitid(:proxy => [:c, :did, :unitid], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.repository_code(:proxy => [:c, :did, :unitid, :repository_code], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.country_code(:proxy => [:c, :did, :unitid, :country_code], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.identifier(:proxy => [:c, :did, :unitid, :identifier], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])


      end # set_terminology

      def synchronize_metadata_on_save
        @synchronize_metadata_on_save || true
      end

      # Build the xml doc
      def self.xml_template
          builder = Nokogiri::XML::Builder.new do |xml|
              xml.c(:level => '') {
                xml.did {
                  xml.unittitle
                  xml.unitid(:repositorycode => '', :countrycode => 'IE')
                }
              }
          end

          return builder.doc
      end

      def retrieve_xpath
         terminology.xpath_for(:title)
      end
      def to_solr(solr_doc=Hash.new)
        super(solr_doc)

        # EAD has several "name" tags, so we merge them together into the SOLR document
        person_array = get_person_array()
        description_array = description
        solr_doc.merge!(ActiveFedora::SolrService.solr_name('person', :stored_searchable) => person_array)
        solr_doc.merge!(ActiveFedora::SolrService.solr_name('person', :facetable) => person_array)
        solr_doc.merge!(ActiveFedora::SolrService.solr_name('description', :searchable) => description_array)

        solr_doc
      end

      def get_person_array()
         return name_coverage | persname_coverage | corpname_coverage | creator
      end

      def description
        return abstract |scope_content | bioghist
      end

      def metadata_path field
        case field
        when :title
          [:c, :did, :unittitle]
        when :abstract
          [:c, :did, :abstract]
        when :bioghist
          [:c, :bioghist]
        when :scope_content
          [:scope_content]
        when :ead_level
          [:c, :ead_level]
        when :language
          [:c, :did, :language]
        when :creator
          [:c, :did, :creator]
        when :creation_date
          [:c, :did, :creation_date]
        when :subject
          [:c, :archdesc, :subject]
        when :name_coverage
          [:c, :archdesc, :name_coverage]
        when :geographical_coverage
          [:c, :archdesc, :geographical_coverage]
        when :physdesc
          [:c, :did, :physdesc]
        when :type
          [:c, :did, :physdesc, :type]
        when :dao_href
          [:c, :did, :dao, :href]
        when :unitid
          [:c, :did, :unitid]
        when :repository_code
          [:c, :did, :unitid, :repository_code]
        when :country_code
          [:c, :did, :unitid, :country_code]
        when :identifier
          [:c, :did, :unitid, :identifier]
        else
          []
        end
      end

      def interchangeable?
        false
      end

      def collection?
        if c.ead_level == ["item"]
          false
        else
          true
        end
      end

      def synchronize_children_to_metadata parent
        # Exit if we have no parent to sync with
        if parent == nil
          return
        end

        # Prevent parent from automatically syncing
        parent.synchronize_if_changed = false

        # Check if the component node in parent XML is different
        parentMetadataXML = parent.descMetadata.to_ng
        childMetadataXML = descMetadata.to_ng

        matchingNodes = parentMetadataXML.xpath(".//parent::unitid[@repository_code='#{repository_code}' and @countrycode='#{country_code}' and "+
                                            " text()=#{unitid}]")
        # Queue synchronization between parent and grandparent
        if parent.descMetadata.class == DRI::Metadata::EncodedArchivalDescriptionComponent 
          Sufia.queue.push(SynchronizeMetadata.new(parent.pid))
        end
      end

      def custom_validations
        errors = Hash.new

        title_result = false
        description_result = false
        unitid_result = false
        cc_result = false
        rc_result = false
        ead_level_result = false

        title.each do |curr_title|
          title_result = true unless curr_title.blank?
        end

        description.each do |curr_description|
          description_result = true unless curr_description.blank?
        end

        c.ead_level.each do |curr_ead_level|
          ead_level_result = true unless curr_ead_level.blank?
        end

        unitid.each do |curr_unitid|
          unitid_result = true unless curr_unitid.blank?
        end

        country_code.each do |curr_cc|
          cc_result = true unless curr_cc.blank?
        end

        repository_code.each do |curr_rc|
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
