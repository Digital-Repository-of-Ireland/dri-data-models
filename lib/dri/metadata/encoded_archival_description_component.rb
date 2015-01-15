module DRI

  module Metadata

    class EncodedArchivalDescriptionComponent < DRI::Metadata::Base

      # OM (Opinionated Metadata) terminology mapping to an EAD Component tag
      set_terminology do |t|
        t.root(:path=>"*", :namespace_prefix => nil)

        t.c(:path=>"*", :namespace_prefix => nil) {
          t.ead_level(:path => {:attribute=>"level"}, :namespace_prefix => nil)
          t.archdesc{
            # Recommendation from DC to EAD crosswalk: archdesc with att level for type
            t.c_level_attr(:path => {:attribute=>"level"}, :namespace_prefix => nil)
            # Subject can be within controlaccess
            t.controlaccess {
              t.head
              # Preferred subject from the guidelines
              t.subject_a(:path=>"subject")
              # Name, Personal, Corporate Name
              t.name_coverage(:path=>"name")
              t.persname_coverage(:path=>"persname")
              t.corpname_coverage(:path=>"corpname")
              t.geographical_coverage(:path=>"geogname")
            }
            # Or just subject within archdesc
            t.subject_b(:path=>"subject")
            # This is a crosswalk from DC publisher into EAD
            t.repository
          }
          t.did {
            t.unittitle
            t.abstract()
            t.note
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
              t.daodesc
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
          }
          t.controlaccess {
            # Or just subject within controlaccess as immediate child of c
            t.subject_c(:path=>"subject")
          }
          t.bioghist {

          }
          t.scopecontent(:path=>"scopecontent", :namespace_prefix => nil)
          t.userestrict {

          }
          t.accessrestrict {

          }
        }

        # DRI Mandatory elements
        # Title
        t.title(:proxy => [:c, :did, :unittitle], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable, :sortable])
        # Description
        t.description(:proxy => [:c, :scopecontent], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        # Creator
        t.creator(:proxy => [:c, :did, :creator], :index_as=>[Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable,  :sortable])
        # Rights - From guidelines, comes from userestrict
        t.rights(:proxy => [:c, :userestrict], :index_as=>[Descriptors.cleaned_displayable, :stored_searchable])
        # Userestrict / Licence
        t.licence(:proxy => [:c, :userestrict], :index_as=>[Descriptors.cleaned_displayable, :stored_searchable])
        # Creation Date
        t.creation_date(:path => 'unitdate[@datechar="Creation"]', :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])

        # DRI Common fields
        # Language
        t.language(:proxy => [:c, :did, :langmaterial, :language], :index_as=>[Descriptors.cleaned_searchable, Descriptors.language_facetable])
        # Publisher
        t.publisher(:proxy => [:c, :archdesc, :repository], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        # Published Date
        # TODO Add published_date field to the terminology. What's the mapped EAD term?
        t.published_date(:ref => [:creation_date], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        # Subject
        t.subject(:proxy => [:c, :archdesc, :controlaccess, :subject_a], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        # Contributor
        t.contributor(:proxy => [:c, :did, :origination, :contributor], :index_as=>[Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable,  :sortable])

        # EAD specific fields
        # Ead Level
        t.ead_level(:proxy => [:c, :ead_level])
        # Abstract
        t.abstract(:proxy => [:c, :did, :abstract], :index_as=>[Descriptors.cleaned_searchable])
        # Bioghist
        t.bioghist(:proxy => [:c, :bioghist], :index_as=>[Descriptors.cleaned_searchable])
        # Scopecontent
        t.scope_content(:proxy => [:c, :scopecontent], :index_as=>[Descriptors.cleaned_searchable])
        # Accessrestrict - access conditions
        t.access_restrict(:proxy => [:c, :accessrestrict], :index_as=>[Descriptors.cleaned_displayable, :stored_searchable])
        # Subject
        t.subject_archdesc(:proxy => [:c, :archdesc, :subject_b], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.subject_control_access(:proxy => [:c, :controlaccess, :subject_c], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])

        # EAD coverage elements within control access headings, authority-controlled search across finding aids
        t.name_coverage(:proxy => [:c, :archdesc, :controlaccess, :name_coverage], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.persname_coverage(:proxy => [:c, :archdesc, :controlaccess, :persname_coverage], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.corpname_coverage(:proxy => [:c, :archdesc, :controlaccess, :corpname_coverage], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.geographical_coverage(:proxy => [:c, :archdesc, :controlaccess, :geographical_coverage], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.temporal_coverage(:path => 'unitdate[not(@datechar="Creation")]', :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])

        t.physdesc(:proxy => [:c, :did, :physdesc], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.type(:proxy => [:c, :did, :physdesc, :type], :index_as=>[:stored_searchable])
        t.type_ead(:proxy => [:c, :ead_level], :index_as=>[Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.dao(:proxy => [:c, :did, :dao])
        t.dao_href(:proxy => [:c, :did, :dao, :href])
        t.dao_desc(:proxy => [:c, :did, :dao, :daodesc])
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

      def to_solr(solr_doc=Hash.new)
        super(solr_doc)

        # FIXME - Index metadata terms that are required for the UI Solr search: title, description, check what else
        solr_doc.merge!(ActiveFedora::SolrService.solr_name('title', :stored_searchable, type: :string) => title)
        # Title
        # title_sorted - A SOLR index for sorting titles
        if (title.length > 0)
          sorted_title = DRI::Metadata::Transformations.transform_title_for_sort(title[0])

          if (sorted_title != "")
            solr_doc.merge!(Solrizer.solr_name('title_sorted', :stored_sortable, type: :string) => [sorted_title])
          end
        end

        # Type
        type_array = type_for_index()

        solr_doc.merge!(Solrizer.solr_name('type', :stored_searchable) => type_array)
        solr_doc.merge!(Solrizer.solr_name('type', :facetable) => type_array)

        # Person  - EAD has several "name" tags, so we merge them together into the SOLR document
        person_array = person_array_for_index()

        solr_doc.merge!(Solrizer.solr_name('person', :facetable) => person_array)
        solr_doc.merge!(Solrizer.solr_name('person', :stored_searchable, type: :text) => person_array | DRI::Metadata::Transformations.transform_name(person_array))

        solr_doc.merge!(Solrizer.solr_name('creator', :facetable) => person_array)
        solr_doc.merge!(Solrizer.solr_name('creator', :stored_searchable, type: :text) => DRI::Metadata::Transformations.transform_name(person_array))

        # all_metadata - A SOLR index of all the text contained in the XML document
        all_metadata = ""
        ng_xml.xpath("//text()").each do |text_node|
          all_metadata += text_node.text
          all_metadata += " "
        end
        solr_doc.merge!(Solrizer.solr_name("all_metadata", :stored_searchable, type: :text) => [all_metadata])

        # TODO Check whether this has to be indexed here
        # Description
        description_array = description_for_index()
        solr_doc.merge!(ActiveFedora::SolrService.solr_name('description', :stored_searchable, type: :string) => description_array)

        # Rights
        rights_array = rights_for_index()
        solr_doc.merge!(ActiveFedora::SolrService.solr_name('rights', :stored_searchable, type: :string) => rights_array)

        # FIXME Licence
        # Licence
        licence_array = licence_for_index()
        solr_doc.merge!(ActiveFedora::SolrService.solr_name('licence', :stored_searchable, type: :string) => licence_array) unless licence_array == []

        # Subject
        subject_array = subject_for_index()

        solr_doc.merge!(Solrizer.solr_name('subject', :stored_searchable) => subject_array)
        solr_doc.merge!(Solrizer.solr_name('subject', :facetable) => subject_array)

        # Creation date
        solr_doc.merge!(Solrizer.solr_name('creation_date', :stored_searchable) => creation_date)
        solr_doc = remove_null_values(solr_doc, "creation_date") if solr_doc[Solrizer.solr_name("creation_date", :stored_searchable)].present?

        # Language
        solr_doc.merge!(Solrizer.solr_name('language', :stored_searchable) => language)

        # Geographical Coverage
        solr_doc.merge!(Solrizer.solr_name('geographical_coverage', :stored_searchable) => geographical_coverage)
        # Temporal Coverage
        solr_doc.merge!(Solrizer.solr_name('temporal_coverage', :stored_searchable) => temporal_coverage)
        solr_doc
      end #to_solr

      # Index Helper Methods
      def person_array_for_index()
         return name_coverage | persname_coverage | corpname_coverage | creator
      end

      # Choose from the first available term from EAD that can be mapped to description
      # Abstract, scope_content, bioghist or daodesc
      def description_for_index()
        return scope_content unless scope_content == []
        return abstract unless abstract == []
        return bioghist unless bioghist == []
        return dao_desc unless dao_desc == []
        return note unless note == []
        return []
        # No concatenation, rather use the order of precedence above
        # return abstract | scope_content | bioghist | dao_desc | note
      end

      # Mapping to UI Rights / License ? userestrict or accessrestrict
      def rights_for_index()
        (rights != [] && !rights.first.include?("CC-BY")) ? rights : ['No rights statement']
      end

      def licence_for_index()
        if (licence != [])
          (licence.first.include?("CC-BY")) ? licence : ['Please see copyright statement']
        end
        return []
      end

      # Mapping to UI subjects: archdesc/controlaccess/subject or subject or controlaccess/subject
      def subject_for_index()
        return subject | subject_archdesc | subject_control_access
      end

      # Mapping to UI subjects: //c/archdesc/@level or type
      def type_for_index()
        return type | type_ead.map(&:capitalize)
      end

      # Helpers for getting elements with multiple mappings
      def get_description()
        return description unless description == []
        return abstract unless abstract == []
        return bioghist unless bioghist ==[]
        return dao_desc unless dao_desc == []
        return note unless note == []
        []
      end

      def get_rights()
        (rights != []) ? rights : []
      end

      def get_subject()
        (subject != []) ? subject : subject_archdesc
      end

      def metadata_path field
        case field
          when :title
            [:c, :did, :unittitle]
          when :description, :scope_content
            [:c, :scopecontent]
          when :abstract
            [:c, :did, :abstract]
          when :bioghist
            [:c, :bioghist]
          when :scope_content
            [:scope_content]
          when :ead_level, :type_ead
            [:c, :ead_level]
          when :language
            [:c, :did, :langmaterial, :language]
          when :creator
            [:c, :did, :creator]
          when :contributor
            [:c, :did, :origination, :contributor]
          when :publisher
            [:c, :archdesc, :repository]
          when :creation_date, :published_date
            [:creation_date]
          when :subject
            [:c, :archdesc, :control_access, :subject_a]
          when :subject_archdesc
            [:c, :archdesc, :subject_b]
          when :subject_control_access
            [:c, :controlaccess, :subject_c]
          when :name_coverage
            [:c, :archdesc, :name_coverage]
          when :persname_coverage
            [:c, :archdesc, :controlaccess, :persname_coverage]
          when :corpname_coverage
            [:c, :archdesc, :controlaccess, :corpname_coverage]
          when :geographical_coverage
            [:c, :archdesc, :geographical_coverage]
          when :temporal_coverage
            [:c, :did, :temporal_coverage]
          when :physdesc
            [:c, :did, :physdesc]
          when :type
            [:c, :did, :physdesc, :type]
          when :dao
            [:c, :did, :dao]
          when :dao_href
            [:c, :did, :dao, :href]
          when :dao_desc
            [:c, :did, :dao, :daodesc]
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
            [:c, :userestrict]
          when :access_restrict
            [:c, :accessrestrict]
          when :note
            [:c, :did, :note]
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
          Sufia.queue.push(SynchronizeMetadata.new(parent.pid))
        end
      end #synchronize_children_to_metadata

      # FIXME Check DRI validations (mandatory recommended)
      def custom_validations
        errors = Hash.new

        # DRI Mandatory elements
        title_result = false
        description_result = false
        creator_result = false
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
        description_for_index().each do |curr_description|
          description_result = true unless curr_description.blank?
        end
        # Rights
        #rights_for_index().each do |curr_rights|
        #  rights_result = true unless curr_rights.blank?
        #end
        # Creator
        creator.each do |curr_creator|
          creator_result = true unless curr_creator.blank?
        end

        # EAD-specific
        ead_level.each do |curr_ead_level|
          ead_level_result = true unless curr_ead_level.blank?
        end

        # For validation of unitid or eadid we now use identifier
        # For EAD header maps to eadid and for components maps to unitid
        identifier.each do |curr_unit_id|
          if (!curr_unit_id.blank? &&
              (!identifier_id.blank? ||
                  !identifier_url.blank? ||
                      !identifier_public_id.blank?))
            unit_id_result = true
          end
          #unit_id_result = true unless curr_unit_id.blank?
        end

        country_code.each do |curr_cc|
          cc_result = true unless curr_cc.blank?
        end

        repository_code.each do |curr_rc|
          rc_result = true unless curr_rc.blank?
        end

        # DRI
        errors[:title] = "can't be blank" if title_result == false
        # FIXME Is description not DRI compulsory??
        #errors[:description] = "can't be blank" if description_result == false
        # FIXME Is creator not DRI compulsory??
        #errors[:creator] = "can't be blank" if creator_result == false
        #errors[:rights] = "can't be blank" if rights_result == false
        #errors[:abstract] = "can't be blank" if description_result == false


        # EAD
        errors[:ead_level] = "can't be blank" if ead_level_result == false
        errors[:identifier] = "can't be blank" if unit_id_result == false
        errors[:country_code] = "can't be blank" if cc_result == false
        # FIXME The repositorycode attribute of unitid should not be compulsory. Fine for NIVAL but not in general
        errors[:repository_code] = "can't be blank" if rc_result == false

        errors
      end #custom_validations

    end #class

  end #module

end #module
