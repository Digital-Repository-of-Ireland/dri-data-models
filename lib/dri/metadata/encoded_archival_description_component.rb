module DRI

  module Metadata

    class EncodedArchivalDescriptionComponent < DRI::Metadata::Base

      # OM (Opinionated Metadata) terminology mapping to an EAD Component tag
      set_terminology do |t|
        t.root(:path=>"*", :namespace_prefix => nil)

        t.c(:path=>"*", :namespace_prefix => nil) {
          t.ead_level(:path => {:attribute=>"level"}, :namespace_prefix => nil)
          t.did {
            t.unittitle
            t.abstract
            t.language(:path=>"langmaterial", :index_as=>[:stored_searchable, :facetable])
            t.creator(:path=>"origination", :index_as=>[:stored_searchable, :facetable])
            t.subject(:path=>"subject", :index_as=>[:stored_searchable, :facetable])
            t.name_coverage(:path=>"name", :index_as=>[:stored_searchable, :facetable])
            t.persname_coverage(:path=>"persname", :index_as=>[:stored_searchable, :facetable])
            t.corpname_coverage(:path=>"corpname", :index_as=>[:stored_searchable, :facetable])
            t.geographical_coverage(:path=>"geogname", :index_as=>[:stored_searchable, :facetable])
            t.creation_date(:path=>"unitdate", :index_as=>[:stored_searchable, :displayable, :facetable]) {
              t.normal(:path => {:attribute=>"normal"}, :namespace_prefix => nil)
              t.datechar(:path => {:attribute=>"datechar"}, :namespace_prefix => nil)
            }
            t.physdesc(:path=>"physdesc", :index_as=>[:stored_searchable, :displayable]) {
              t.type(:path=>"genreform", :index_as=>[:stored_searchable, :displayable, :facetable])
            }
            t.dao(:path=>"dao") {
              t.href(:path => {:attribute=>"href"}, :namespace_prefix => nil)
            }

            # We need to keep track of the unitid in order to sync this XML snippet to the correct
            # component tag in the complete EAD XML datastream in the collection object!
            t.unitid(:path=>"unitid", :index_as=>[:stored_searchable], :namespace_prefix => nil) {
              t.repository_code(:path => {:attribute=>"repositorycode"}, :index_as=>[:stored_searchable], :namespace_prefix => nil)
              t.country_code(:path => {:attribute=>"countrycode"}, :index_as=>[:stored_searchable], :namespace_prefix => nil)
              t.identifier(:path => {:attribute=>"identifier"}, :index_as=>[:stored_searchable], :namespace_prefix => nil)
            }
          }
          t.bioghist {

          }
          t.scopecontent {

          }
        }
        t.title(:proxy => [:c, :did, :unittitle], :index_as=>[:stored_searchable, :displayable, :sortable])
        t.abstract(:proxy => [:c, :did, :abstract], :index_as=>[:stored_searchable])
        t.bioghist(:proxy => [:c, :bioghist], :index_as=>[:stored_searchable])
        t.scope_content(:proxy => [:c, :scopecontent], :index_as=>[:stored_searchable])
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
        solr_doc.merge!(ActiveFedora::SolrService.solr_name('description', :stored_searchable) => description_array)
        solr_doc.merge!(ActiveFedora::SolrService.solr_name('description', :facetable) => description_array)

        solr_doc
      end

      def get_person_array()
         return c.did.name_coverage | c.did.persname_coverage | c.did.corpname_coverage | c.did.creator
      end

      def description
        return c.did.abstract | c.scopecontent | c.bioghist
      end

      def metadata_path field
        case field
        #when :c
        #  [:c]
        when :title
          [:title]
        when :abstract
          [:abstract]
        when :bioghist
          [:bioghist]
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
        when :name_coverage
          [:c, :did, :name_coverage]
        when :geographical_coverage
          [:c, :did, :geographical_coverage]
        when :physdesc
          [:c, :did, :physdesc]
        when :type
          [:c, :did, :physdesc, :type]
        when :dao
          [:c, :did, :dao]
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

        c.did.unittitle.each do |curr_title|
          title_result = true unless curr_title.blank?
        end

        description.each do |curr_description|
          description_result = true unless curr_description.blank?
        end

        c.ead_level.each do |curr_ead_level|
          ead_level_result = true unless curr_ead_level.blank?
        end

        c.did.unitid.each do |curr_unitid|
          unitid_result = true unless curr_unitid.blank?
        end

        c.did.unitid.country_code.each do |curr_cc|
          cc_result = true unless curr_cc.blank?
        end

        c.did.unitid.repository_code.each do |curr_rc|
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
