module DRI

  module Metadata

    class EncodedArchivalDescriptionComponent < DRI::Metadata::Base

      # OM (Opinionated Metadata) terminology mapping to an EAD Component tag
      set_terminology do |t|
        t.root(:path=>"*", :namespace_prefix => nil)
        # Elements that can occur nested within other elements: multiple options
        t.p(:path => "p", :namespace_prefix => nil)
        # They can be used as subjects or even in the title
        t.geographic_name(:path=>"geogname") {
          t.role(:path => {:attribute=>"role"})
        }
        t.name_(:path=>"name") {
          t.role(:path => {:attribute=>"role"})
        }
        t.persname_(:path=>"persname[not(parent::origination[@label='Creator:']) and not(@role='creator') and not(@role='cre') and not(@role='aut')]") {
          t.role(:path => {:attribute=>"role"})
        }
        t.corpname_(:path=>"corpname") {
          t.role(:path => {:attribute=>"role"})
        }
        t.famname_(:path=>"famname") {
          t.role(:path => {:attribute=>"role"})
        }
        t.date_(:path=>"date") {
          t.normal(:path => {:attribute=>"normal"}, :namespace_prefix => nil)
          t.type(:path => {:attribute=>"type"}, :namespace_prefix => nil)
        }

        t.date_text(:ref => [:date], :attributes => {"normal" => :none})

        t.c(:path=>"*", :namespace_prefix => nil) {
          t.ead_level(:path => {:attribute=>"level"}, :namespace_prefix => nil)
          t.other(:path => {:attribute=>"otherlevel"}, :namespace_prefix => nil)
          t.archdesc{
            # Recommendation from DC to EAD crosswalk: archdesc with att level for type
            t.c_level_attr(:path => {:attribute=>"level"}, :namespace_prefix => nil)
            # Subject can be within controlaccess
            t.controlaccess {
              t.p_(:ref => [:p])
              t.head
              # Preferred subject from the guidelines
              t.subject_a(:path=>"subject")
              t.name_coverage(:path => "name", :attributes => {:role => "subject"})
              t.persname_coverage(:path => "persname", :attributes => {:role => "subject"})
              t.corpname_coverage(:path => "corpname", :attributes => {:role => "subject"})
              t.famname_coverage(:path => "famname", :attributes => {:role => "subject"})
              # Geographical coverage
              t.geographical_coverage(:path => "geogname", :attributes => {:role => "subject"})
            }
            # Or just subject within archdesc
            t.subject_archdesc(:path=>"subject")
          }
          t.did {
            t.unittitle {
              t.geographical_title(:ref => [:geographic_name])
            }
            t.abstract {
              t.p_(:ref => [:p])
            }
            t.note {
              t.p_(:ref => [:p])
            }
            # Language within did
            t.langmaterial {
              t.language(:path => "language", :namespace_prefix => nil){
                t.langcode_attr(:path => {:attribute=>"langcode"}, :namespace_prefix => nil)
              }
            }
            # FIXME Creator in NIVAL uses label="Creator:"
            t.creator(:path=>"origination")

            t.origination(:path=>"origination") {
              t.contributor(:path=>"persname", :attributes=>{:role=>"contributor"}, :namespace_prefix => nil)
            }

            t.unitdate(:path=>"unitdate") {
              t.normal(:path => {:attribute=>"normal"}, :namespace_prefix => nil)
              t.datechar(:path => {:attribute=>"datechar"}, :namespace_prefix => nil)
            }

            #t.creation_date(:path=>"unitdate", :attributes=>{:datechar=>"Creation"}) {
            #  t.normal(:path => {:attribute=>"normal"}, :namespace_prefix => nil)
            #  t.datechar(:path => {:attribute=>"datechar"}, :namespace_prefix => nil)
            #}

            #t.temporal_coverage(:path=>"unitdate") {
            #  t.normal(:path => {:attribute=>"normal"}, :namespace_prefix => nil)
            #  t.datechar(:path => {:attribute=>"datechar"}, :namespace_prefix => nil)
            #}

            t.physdesc(:path=>"physdesc") {
              t.type(:path=>"genreform")
            }
            t.dao(:path=>"dao") {
              t.href(:path => {:attribute=>"href"}, :namespace_prefix => nil)
              t.daodesc {
                t.p_(:ref => [:p])
              }
            }

            # We need to keep track of the unitid in order to sync this XML snippet to the correct
            # component tag in the complete EAD XML datastream in the collection object!
            t.unitid(:path=>"unitid") {
              t.repository_code(:path => {:attribute=>"repositorycode"}, :namespace_prefix => nil)
              t.country_code(:path => {:attribute=>"countrycode"}, :namespace_prefix => nil)
              t.identifier_attr(:path => {:attribute=>"identifier"}, :namespace_prefix => nil)
              t.url_attr(:path => {:attribute=>"url"}, :namespace_prefix => nil)
              t.public_id_attr(:path => {:attribute=>"publicid"}, :namespace_prefix => nil)
            }
            # Institute: Institution responsible for providing intellectual access to the materials being described
            t.repository {
              t.p_(:ref => [:p])
              t.corpname {
                t.p_(:ref => [:p])
              }
            }
          }
          t.controlaccess {
            t.p_(:ref => [:p])
            # Or just subject within controlaccess as immediate child of c
            t.subject_c(:path=>"subject")
            # Name, Personal, Corporate Name
            t.name_coverage(:ref => [:name], :attributes => {:role => "subject"})
            t.persname_coverage(:ref => [:persname], :attributes => {:role => "subject"})
            t.corpname_coverage(:ref => [:corpname], :attributes => {:role => "subject"})
            t.famname_coverage(:ref => [:famname], :attributes => {:role => "subject"})
            t.geographical_coverage(:ref => [:geographic_name], :attributes => {:role => "subject"})
          }
          t.bioghist {
            t.p_(:ref => [:p])
          }
          t.scopecontent(:path=>"scopecontent", :namespace_prefix => nil) {
            t.head
            t.p_(:ref => [:p])
          }
          t.userestrict {
            t.p_(:ref => [:p])
          }
          t.accessrestrict {
            t.p_(:ref => [:p])
          }
          t.related_material(:path => "relatedmaterial", :namespace_prefix => nil) {
            t.title
            t.p_(:ref => [:p])
          }
          t.alternative_form(:path => "altformavail", :namespace_prefix => nil) {
            t.p_(:ref => [:p])
          }
        }

        # DRI Mandatory elements
        # Title
        t.title(:proxy => [:c, :did, :unittitle], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable, :sortable])
        # Description
        t.description(:proxy => [:c, :scopecontent, :p], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        # Creator
        t.creator(:proxy => [:c, :did, :creator], :index_as=>[Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable,  :sortable])
        # Rights - From guidelines, comes from userestrict
        t.rights(:proxy => [:c, :userestrict, :p], :index_as=>[Descriptors.cleaned_displayable, :stored_searchable])
        # Userestrict / Licence
        t.licence(:proxy => [:c, :userestrict, :p], :index_as=>[Descriptors.cleaned_displayable, :stored_searchable])
        # Creation Date, now with generic xpath query: @datechar="creation" is now case-insensitive
        t.creation_date(:path => 'unitdate[@datechar[contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "creation")] and not(@normal)]')

        # DRI Common fields
        # Language
        t.language(:proxy => [:c, :did, :langmaterial, :language], :index_as=>[Descriptors.cleaned_searchable, Descriptors.language_facetable])
        # Publisher
        t.publisher(:proxy => [:c, :did, :repository], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        # Published Date
        # TODO Add published_date field to the terminology. What's the mapped EAD term?
        t.published_date(:path => 'unitdate[@datechar[contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "publication")] and not(@normal)]')
        # Subject
        t.subject(:proxy => [:c, :controlaccess, :subject_c], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        # Contributor
        t.contributor(:proxy => [:c, :did, :origination, :contributor], :index_as=>[Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable,  :sortable])

        # EAD specific fields
        # Ead Level
        t.ead_level(:proxy => [:c, :ead_level])
        t.ead_level_other(:proxy => [:c, :other])
        # Abstract
        t.abstract(:proxy => [:c, :did, :abstract], :index_as=>[Descriptors.cleaned_searchable])
        # Bioghist
        t.bioghist(:proxy => [:c, :bioghist], :index_as=>[Descriptors.cleaned_searchable])
        # Scopecontent
        t.scope_content(:proxy => [:c, :scopecontent, :p], :index_as=>[Descriptors.cleaned_searchable])
        # Accessrestrict - access conditions
        t.access_restrict(:proxy => [:c, :accessrestrict, :p], :index_as=>[Descriptors.cleaned_displayable, :stored_searchable])
        # Subject
        t.subject_archdesc(:proxy => [:c, :archdesc, :subject_archdesc], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.subject_archdesc_controlaccess(:proxy => [:c, :archdesc, :controlaccess, :subject_a], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        # EAD coverage elements within control access headings, authority-controlled search across finding aids
        t.name_coverage(:proxy => [:c, :controlaccess, :name_coverage], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.persname_coverage(:proxy => [:c, :controlaccess, :persname_coverage], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.corpname_coverage(:proxy => [:c, :controlaccess, :corpname_coverage], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.famname_coverage(:proxy => [:c, :controlaccess, :famname_coverage], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.geographical_coverage(:proxy => [:c, :controlaccess, :geographical_coverage], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        # Generic xpath query: @datechar="creation" is now case-insensitive
        t.temporal_coverage(:path => 'unitdate[@datechar[not(contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "creation")) and not(contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "publication"))] and not(@normal)]')

        t.physdesc(:proxy => [:c, :did, :physdesc], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.type(:proxy => [:c, :did, :physdesc, :type], :index_as=>[:stored_searchable])
        t.type_ead(:proxy => [:c, :ead_level], :index_as=>[Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.dao(:proxy => [:c, :did, :dao])
        t.dao_href(:proxy => [:c, :did, :dao, :href])
        t.dao_desc(:proxy => [:c, :did, :dao, :daodesc, :p])
        #t.unitid(:proxy => [:c, :did, :unitid], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        #t.eadid(:proxy => [:c, :did, :unitid], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.repository_code(:proxy => [:c, :did, :unitid, :repository_code], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.country_code(:proxy => [:c, :did, :unitid, :country_code], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.identifier(:proxy => [:c, :did, :unitid], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.identifier_url(:proxy => [:c, :did, :unitid, :url_attr], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.identifier_id(:proxy => [:c, :did, :unitid, :identifier_attr], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.identifier_public_id(:proxy => [:c, :did, :unitid, :public_id_attr], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        # EAD elements
        t.note(:proxy => [:c, :did, :note], :index_as=>[Descriptors.cleaned_searchable])
        # Institute / Depositing Institution
        t.institute(:proxy => [:c, :did, :repository, :corpname], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])

        # Related Material
        t.related_material(:path => "extref/@href[ancestor::relatedmaterial]", :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        # Alternative Form Available
        t.alternative_form(:path => "extref/@href[ancestor::altformavail]", :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])

        t.creation_date_idx(:path => 'unitdate[@datechar[contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "creation")]]/@normal')
        t.creation_date_idx_d(:path => 'unitdate[@datechar[contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "creation")] and @normal]')
        t.published_date_idx(:path => 'unitdate[@datechar[contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "publication")]]/@normal')
        t.published_date_idx_d(:path => 'unitdate[@datechar[contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "publication")] and @normal]')
        t.temporal_coverage_idx(:path => 'unitdate[@datechar[not(contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "creation")) and not(contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "publication"))]]/@normal')
        t.temporal_coverage_idx_d(:path => 'unitdate[@datechar[not(contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "creation")) and not(contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "publication"))] and @normal]')
        t.date_idx(:proxy => [:date, :normal])
        t.date_idx_d(:path => "date[@normal]")

      end # set_terminology

      def synchronize_metadata_on_save
        @synchronize_metadata_on_save || true
      end

      #def from_xml(xml=nil)
      #  if xml.nil?
      #    # noop: handled in #ng_xml accessor.. tmpl.ng_xml = self.xml_template
      #  elsif
      #    self.ng_xml = xml
      #  end
      #end
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

      def to_solr(solr_doc=Hash.new, opts = {})
        solr_doc = super(solr_doc)

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('title', :stored_searchable, type: :string) => title)
        # Title
        # title_sorted - A SOLR index for sorting titles
        if (title.length > 0)
          sorted_title = DRI::Metadata::Transformations.transform_title_for_sort(title[0])

          if (sorted_title != "")
            solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('title_sorted', :stored_sortable, type: :string) => [sorted_title])
          end
        end

        # Type
        type_array = type_for_index()

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('type', :stored_searchable) => type_array)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('type', :facetable) => type_array)

        # Person  - EAD has several "name" tags, so we merge them together into the SOLR document
        person_array = person_array_for_index()

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('person', :facetable) => person_array)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('person', :stored_searchable, type: :text) => person_array | DRI::Metadata::Transformations.transform_name(person_array))

        # Creator
        creator_array = creator_for_index()

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('creator', :facetable) => creator_array)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('creator', :stored_searchable, type: :text) => DRI::Metadata::Transformations.transform_name(creator_array))

        # all_metadata - A SOLR index of all the text contained in the XML document
        all_metadata = ""
        ng_xml.xpath("//text()").each do |text_node|
          all_metadata += text_node.text
          all_metadata += " "
        end
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name("all_metadata", :stored_searchable, type: :text) => [all_metadata])

        # TODO Check whether this has to be indexed here
        # Description
        description_array = description_for_index()
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('description', :stored_searchable, type: :string) => description_array)

        # Rights
        rights_array = rights_for_index()
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('rights', :stored_searchable, type: :string) => rights_array)

        # FIXME Licence
        # Licence
        licence_array = licence_for_index()
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('licence', :stored_searchable, type: :string) => licence_array) unless licence_array == []

        # Subject: generic, name and place
        subject_array = subject_for_index()

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('subject', :stored_searchable) => subject_array)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('subject', :facetable) => subject_array)

        subject_name_array = subject_name_for_index()
        subject_place_array = subject_place_for_index()
        #subject_temporal_array = subject_temporal_for_index()

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('name_coverage', :stored_searchable) => subject_name_array)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('name_coverage', :facetable) => subject_name_array)

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('geographical_coverage', :stored_searchable) => subject_place_array)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('geographical_coverage', :facetable) => subject_place_array)

        #solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('temporal_coverage', :stored_searchable) => subject_temporal_array)
        #solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('temporal_coverage', :facetable) => subject_temporal_array)

        # Display of Creation Date
        creation_date_array = creation_date_for_index()
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('creation_date', :stored_searchable) => creation_date_array) unless creation_date_array == []
        solr_doc = remove_null_values(solr_doc, "creation_date") if solr_doc[ActiveFedora::SolrQueryBuilder.solr_name("creation_date", :stored_searchable)].present?

        # Language
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('language', :stored_searchable) => language)

        # Geographical Coverage
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('geographical_coverage', :stored_searchable) => geographical_coverage)

        # Temporal Coverage
        #solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('temporal_coverage', :stored_searchable) => temporal_coverage)

        # FIXME - To be removed once the workflow is implemented Institute and sponsor/Depositing Institute: archdesc/did/repository
        institute_array = institute_for_index()
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('institute', :facetable) => institute_array) unless institute_array == []
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('institute', :stored_searchable, type: :string) => institute_array) unless institute_array == []
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('depositing_institute', :stored_searchable, type: :string) => institute_array) unless institute_array == []
        # depositing_institute_ssm - the dri_app looks for this type of indexed field at object-level display
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('depositing_institute', :displayable, type: :string) => institute_array) unless institute_array == []

        # Index related_material and alternative_form_available
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('related_material', :stored_searchable) => related_material) unless related_material == []
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('alternative_form', :stored_searchable) => alternative_form) unless alternative_form == []

        # Indexing dates for display + COOL date range
        # Display of Subject(Temporal)
        subject_temporal_array = subject_temporal_for_index()
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('temporal_coverage', :stored_searchable) => subject_temporal_array)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('temporal_coverage', :facetable) => subject_temporal_array)

        # Creation_date_idx field is necessary for inheriting the date from the parent if not present
        if (creation_date_idx != [])
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('creation_date_idx', :stored_searchable) => creation_date_idx)
        else
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('creation_date_idx', :stored_searchable) => get_field_from_parent("creation_date_idx"))
        end
        # Display of Creation Date
        unless published_date_idx == [] && published_date == []
          pdate_array = published_date.collect! do |value|
            DRI::Metadata::Transformations.create_dcmi_period(value)
          end
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('published_date', :stored_searchable) => display_date_for_index(published_date_idx, published_date_idx_d) | pdate_array)
        end
        # Index date ranges
        date_ranges = date_ranges_for_index() # ALL the date ranges

        # Creation date dateRange index
        cdate_ranges = date_ranges.select {|key, value| ["creation_date"].include?(key)}
        solr_doc.merge!(DRI::Metadata::Transformations::CREATION_DATE_RANGE_SOLR_FIELD => DRI::Metadata::Transformations::transform_date_ranges(cdate_ranges)) unless cdate_ranges == {}

        # Published date dateRange index
        pdate_ranges = date_ranges.select {|key, value| ["published_date"].include?(key)}
        solr_doc.merge!(DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_SOLR_FIELD => DRI::Metadata::Transformations::transform_date_ranges(pdate_ranges)) unless pdate_ranges == {}

        # Subject date dateRange index
        sdate_ranges = date_ranges.select {|key, value| ["subject_date"].include?(key)}
        solr_doc.merge!(DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_SOLR_FIELD => DRI::Metadata::Transformations::transform_date_ranges(sdate_ranges)) unless sdate_ranges == {}


        solr_doc
      end #to_solr

      # Index Helper Methods
      def person_array_for_index()
         return name_coverage | persname_coverage | corpname_coverage | creator | persname | corpname | name
      end

      # Choose from the first available term from EAD that can be mapped to description
      # Abstract, scope_content, or daodesc
      def description_for_index()
        return description unless description == []
        return dao_desc unless dao_desc == []
        return abstract unless abstract == []
        #return bioghist unless bioghist == []
        #return note unless note == []
        return []
        # No concatenation, instead use the order of precedence above
        # return abstract | scope_content | bioghist | dao_desc | note
      end

      # Mapping to c/userestrict (Rights in the UI)
      # If the component does not have this information it is then inherited from the immediate parent
      # and returned for its indexing as Rights
      def rights_for_index()
        if (rights != [])
          (!rights.first.include?("CC-BY")) ? (return rights) : (return ['No rights statement'])
        else
          get_field_from_parent("rights")
        end
      end

      # Maps also to c/userestrict, but if it contains licence info
      # it is then returned as licence information for indexing
      def licence_for_index()
        if (licence != [])
          (licence.first.include?("CC-BY")) ? licence : ['Please see rights statement']
        else
          return ['Please see rights statement']
        end
      end

      # Maps to unitdate/@datechar="Creation", if the component does not have this information, it is then
      # inherited from the immediate parent (similar to rights - userestrict)
      def creation_date_for_index()
        if (creation_date_idx != [] || creation_date != [])
          cdate_array = creation_date.collect! do |value|
            DRI::Metadata::Transformations.create_dcmi_period(value)
          end
          return display_date_for_index(creation_date_idx, creation_date_idx_d) | cdate_array
        else
          # Inherit the information
          return get_field_from_parent("creation_date")
        end
      end

      # Maps to origination/persname, if the component does not have this information, it is then
      # inherited from the immediate parent (similar to rights - userestrict)
      def creator_for_index()
        if (creator != [])
          return creator
        else
          # Inherit the information
          get_field_from_parent("creator")
        end
      end

      # Get the Institute Information from the parent collection
      def institute_for_index()
        if (institute != [])
          return institute
        else
          # Get the Institute from the parent collection, if available
          get_field_from_parent("institute")
        end
      end

      def get_field_from_parent(field_name)
        uri_terms = uri.split("/")
        id = uri_terms[uri_terms.size()-2] # get the object's id
        fedora_object = DRI::EncodedArchivalDescription.find(id)
        unless fedora_object.nil? || fedora_object.governing_collection.nil?
          solr_query = "id:\"#{fedora_object.governing_collection.id.to_s}\""
          docs = ActiveFedora::SolrService.query(solr_query, :defType => "edismax")

          parent_field = docs.first[ActiveFedora::SolrQueryBuilder.solr_name(field_name, :stored_searchable, type: :string)] unless docs.empty?
        end

        if !parent_field.nil?
          return parent_field
        else
          return []
        end
      end

      # Mapping to UI subjects: archdesc/controlaccess/subject or subject or controlaccess/subject
      def subject_for_index()
        return subject | subject_archdesc | subject_archdesc_controlaccess
      end

      # These are DRI Subject(Name)
      def subject_name_for_index()
        # Format persname to include role
        persname_roles = persname.collect!.with_index do |name, idx|
          name = (persname.role[idx].nil?) ? name : (name + " (#{persname.role[idx]})")
        end

        return name | persname_roles | corpname
      end

      # These are DRI Subject(Place)
      def subject_place_for_index()
        return geographic_name
      end

      # These are DRI Subject(Place)
      def subject_temporal_for_index()
        dtext_array = date_text.collect! do |value|
          DRI::Metadata::Transformations.create_dcmi_period(value)
        end
        tcoverage_array = temporal_coverage.collect! do |value|
          DRI::Metadata::Transformations.create_dcmi_period(value)
        end
        return display_date_for_index(temporal_coverage_idx, temporal_coverage_idx_d) |
            display_date_for_index(date_idx, date_idx_d) |
            tcoverage_array |
            dtext_array
      end

      # Return all date ranges formatted in the right format for indexing and single dates
      # Format: start_date/end_date (ISO8601)
      # @return Hash with all the dates present in the metadata to be indexed as date ranges
      def date_ranges_for_index()
        dates_hash = Hash.new

        dates_hash["creation_date"] = creation_date_idx == [] ? get_field_from_parent("creation_date_idx") : creation_date_idx
        dates_hash["published_date"] = published_date_idx
        dates_hash["subject_date"] = temporal_coverage_idx | date_idx

        return dates_hash
      end

      def display_date_for_index(date_field=[], date_field_d=[])
        date_field.collect!.with_index do |value, idx|
          begin
            # Date range in ISO8601 format: YYYYmmdd/YYYYmmdd
            if (value.include?('/'))
              range = value.split("/")
              sdate = ISO8601::DateTime.new(range[0]).strftime("%b %d, %Y") #start date
              edate = ISO8601::DateTime.new(range[1]).strftime("%b %d, %Y") #end date
              if idx <= (date_field_d.length - 1)
                DRI::Metadata::Transformations.create_dcmi_period(date_field_d[idx], range[0], range[1])
              else
                DRI::Metadata::Transformations.create_dcmi_period(sdate << ' - ' << edate, range[0], range[1])
              end
            else
              if idx <= (date_field_d.length - 1)
                DRI::Metadata::Transformations.create_dcmi_period(date_field_d[idx], value)
              else
                sdate = ISO8601::DateTime.new(value).strftime("%b %d, %Y")
                DRI::Metadata::Transformations.create_dcmi_period(sdate, value)
              end
            end
          rescue ISO8601::Errors::StandardError
            if idx <= (date_field_d.length - 1)
              DRI::Metadata::Transformations.create_dcmi_period(date_field_d[idx]) # DCMI Period 'name' is the md value
            else
              DRI::Metadata::Transformations.create_dcmi_period(value) # DCMI Period 'name' is the md value
            end
          end
        end
      end

      # Mapping to UI subjects: //c/archdesc/@level or type
      def type_for_index()
        return type_ead.map(&:capitalize) | ead_level_other.map(&:capitalize) | type
      end

      def metadata_path field
        case field
          when :title
            [:c, :did, :unittitle]
          when :description, :scope_content
            [:c, :scopecontent, :p]
          when :abstract
            [:c, :did, :abstract]
          when :bioghist
            [:c, :bioghist]
          when :scope_content
            [:scope_content]
          when :ead_level, :type_ead
            [:c, :ead_level]
          when :ead_level_other
            [:c, :other]
          when :language
            [:c, :did, :langmaterial, :language]
          when :creator
            [:c, :did, :creator]
          when :contributor
            [:c, :did, :origination, :contributor]
          # FIXME Check the mapping for publisher, for components!
          when :publisher
            [:c, :did, :repository]
          when :creation_date
            [:creation_date]
          when :published_date
            [:published_date]
          when :subject
            [:c, :control_access, :subject_c]
          when :subject_archdesc
            [:c, :archdesc, :subject_archdesc]
          when :subject_archdesc_controlaccess
            [:c, :archdesc, :controlaccess, :subject_a]
          when :name_coverage
            [:c, :controlaccess, :name_coverage]
          when :famname_coverage
            [:c, :controlaccess, :famname_coverage]
          when :persname_coverage
            [:c, :controlaccess, :persname_coverage]
          when :corpname_coverage
            [:c, :controlaccess, :corpname_coverage]
          when :famname_coverage
            [:c, :controlaccess, :famname_coverage]
          when :geographical_coverage
            [:c, :controlaccess, :geographical_coverage]
          when :temporal_coverage
            [:temporal_coverage]
          when :physdesc
            [:c, :did, :physdesc]
          when :type
            [:c, :did, :physdesc, :type]
          when :dao
            [:c, :did, :dao]
          when :dao_href
            [:c, :did, :dao, :href]
          when :dao_desc
            [:c, :did, :dao, :daodesc, :p]
          #when :unitid, :eadid
          #  [:c, :did, :unitid]
          when :repository_code
            [:c, :did, :unitid, :repository_code]
          when :country_code
            [:c, :did, :unitid, :country_code]
          when :identifier
            [:c, :did, :unitid]
          when :identifier_id
            [:c, :did, :unitid, :identifier_attr]
          when :identifier_url
            [:c, :did, :unitid, :url_attr]
          when :identifier_public_id
            [:c, :did, :unitid, :public_id_attr]
          when :rights, :licence
            [:c, :userestrict, :p]
          when :access_restrict
            [:c, :accessrestrict, :p]
          when :note
            [:c, :did, :note]
          when :institute
            [:c, :did, :repository, :corpname]
          when :related_material
            [:c, :related_material, :p]
          when :alternative_form
            [:c, :alternative_form, :p]
          else
            []
        end
      end #metadata_path

      def interchangeable?
        false
      end

      def collection?
        (ead_level == ["item"]) ? false : true
      end

      # TODO Revise this method for EAD updates
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
        # FIXME Identifying nodes via: unitid and (attributes identifier or publicid or url)
        matchingNodes = parentMetadataXML.xpath(".//parent::unitid[@repository_code='#{repository_code}' and @countrycode='#{country_code}' and "+
                                            " text()=#{identifier}]")
        # Queue synchronization between parent and grandparent
        if parent.descMetadata.class == DRI::Metadata::EncodedArchivalDescriptionComponent
          Sufia.queue.push(SynchronizeMetadata.new(parent.id))
        end
      end #synchronize_children_to_metadata

      # FIXME Check DRI validations (mandatory recommended)
      def custom_validations
        errors = Hash.new

        # DRI Mandatory elements (At collection-level)
        title_result = false
        #description_result = false
        #creator_result = false
        #rights_result = false

        # EAD-specific validation from best practices
        unit_id_result = false
        cc_result = false
        rc_result = false
        ead_level_result = false

        # Title
        title.each do |curr_title|
          title_result = true unless curr_title.blank?
        end

        # Description
        #description_for_index().each do |curr_description|
        #  description_result = true unless curr_description.blank?
        #end
        # Rights
        #rights_for_index().each do |curr_rights|
        #  rights_result = true unless curr_rights.blank?
        #end
        # Creator
        #creator.each do |curr_creator|
        #  creator_result = true unless curr_creator.blank?
        #end

        # EAD-specific
        ead_level.each do |curr_ead_level|
          ead_level_result = true unless curr_ead_level.blank?
        end

        # For validation of unitid or eadid we now use identifier
        # For EAD header maps to eadid and for components maps to unitid
        identifier.each_with_index do |curr_unit_id, index|
          # Removed this for unitid, it is only compulsory for EADID; just check for unitid presence
          #if (!curr_unit_id.blank? &&
          #    (!identifier_id.blank? ||
          #        !identifier_url.blank? ||
          #            !identifier_public_id.blank?))
          #  unit_id_result = true
          #end
          # Handle the case where multiple unitid are present: only the first should carry the attributes
          if (index == 0)
            unit_id_result = true unless curr_unit_id.blank?
            country_code.each do |curr_cc|
              cc_result = true unless curr_cc.blank?
            end

            repository_code.each do |curr_rc|
              rc_result = true unless curr_rc.blank?
            end
          end
        end

        # DRI
        errors[:title] = "can't be blank" if title_result == false

        #if (collection?)
          #errors[:description] = "can't be blank" if description_result == false
          #errors[:creator] = "can't be blank" if creator_result == false
          #errors[:rights] = "can't be blank" if rights_result == false
        #end

        #errors[:abstract] = "can't be blank" if description_result == false


        # EAD
        errors[:ead_level] = "can't be blank" if ead_level_result == false

        # UNITID validation
        # 1. unitid must be present
        # 1.1 the attribute mainagencycode is recommended for unitid
        # 1.2 the attribute countrycode is recommended for unitid
        if (unit_id_result == false)
          errors[:identifier] = "can't be blank"
        elsif (cc_result == false || rc_result == false)
          errors[:identifier] = "invalid use"
          errors[:country_code] = "can't be blank" if cc_result == false
          errors[:repository_code] = "can't be blank" if rc_result == false
        end

        errors
      end #custom_validations

    end #class

  end #module

end #module
