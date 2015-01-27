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
              t.identifier_attr(:path => {:attribute=>"identifier"}, :namespace_prefix => nil)
              t.url_attr(:path => {:attribute=>"url"}, :namespace_prefix => nil)
              t.public_id_attr(:path => {:attribute=>"publicid"}, :namespace_prefix => nil)
            }
            t.filedesc {
              t.titlestmt {
                t.title(:path=>"titleproper")
              }
              t.publicationstmt {
                t.publisher()
                t.date {
                  t.normal(:path => {:attribute=>"normal"}, :namespace_prefix => nil)
                  t.datechar(:path => {:attribute=>"datechar"}, :namespace_prefix => nil)
                }
              }
              # Also added from recommendation
              t.notestmt {
                t.note
              }
            }
            t.profiledesc {
              # Collection creation_date
              t.creation {
                t.date {
                  t.normal(:path => {:attribute=>"normal"}, :namespace_prefix => nil)
                  t.datechar(:path => {:attribute=>"datechar"}, :namespace_prefix => nil)
                }
              }
              # Language within eadheader
              t.langusage {
                t.language(:path => "language", :namespace_prefix => nil){
                  t.langcode_attr(:path => {:attribute=>"langcode"}, :namespace_prefix => nil)
                }
              }
            }
          }
          t.archdesc {
            t.repository
            t.scopecontent {
            }
            # Subject can be
            t.controlaccess {
              t.head
              # Preferred subject from the guidelines
              t.subject_a(:path=>"subject")
              # Name, Personal, Corporate Name
              t.name_coverage(:path=>"name")
              t.persname_coverage(:path=>"persname")
              t.corpname_coverage(:path=>"corpname")
              # Geographical coverage
              t.geographical_coverage(:path=>"geogname")
            }
            t.subject_b(:path=>"subject")

            t.name_coverage(:path=>"name")
            t.persname_coverage(:path=>"persname")
            t.corpname_coverage(:path=>"corpname")
            t.geographical_coverage(:path=>"geogname")
            t.ead_level(:path => {:attribute=>"level"}, :namespace_prefix => nil)
            t.did(:path => "did", :namespace_prefix => nil) {
              t.abstract()
              # TODO Decide the preference order for language: within eadheader or within did
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
              t.physdesc(:path=>"physdesc") {
                t.type(:path=>"genreform")
              }
              t.dao(:path=>"dao") {
                t.href(:path => {:attribute=>"href"}, :namespace_prefix => nil)
                t.daodesc
              }
            }
            t.bioghist {
            }
            # Rights either userestrict or accessrestrict
            t.userestrict {
            }
            t.accessrestrict{
            }
          }
        }
        # Proxies for the DRI fields
        # Title (collection-level, M)
        t.title(:proxy => [:ead, :eadheader, :filedesc, :titlestmt, :title], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        # Description (collection-level, M)
        t.description(:proxy => [:ead, :archdesc, :scopecontent], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        # Language //archdesc/did/langmaterial/language (collection-level, R best practice) but for NIVAL... use langusage in the eadHeader
        t.language(:proxy => [:ead, :eadheader, :profiledesc, :langusage, :language], :index_as=>[Descriptors.cleaned_searchable,  Descriptors.language_facetable])
        # Creator (collection-level, M)
        t.creator(:proxy => [:ead, :archdesc, :did, :creator], :index_as=>[Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable,  :sortable])
        # Contributor (R)
        t.contributor(:proxy => [:ead, :archdesc, :did, :origination, :contributor], :index_as=>[Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable,  :sortable])
        # Publisher (collection-level, DRI pre-populated)
        t.publisher(:proxy => [:ead, :eadheader, :filedesc, :publicationstmt, :publisher], :index_as=>[Descriptors.cleaned_searchable, :sortable])
        # Published Date (collection-level, DRI pre-populated)
        # TODO Add published_date field to the terminology. What's the mapped EAD term?
        t.published_date(:proxy => [:ead, :eadheader, :filedesc, :publicationstmt, :date], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        # Creation Date: creation_date within archdesc first, if not present, then look in eadheader/profiledesc (collection-level, M)
        t.creation_date(:path => 'unitdate[@datechar="Creation"]', :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        # ORIGINAL - t.creation_date(:proxy => [:ead, :archdesc, :did, :creation_date], :index_as=>[Descriptors.cleaned_searchable])
        # Subject (collection-level, R)
        t.subject(:proxy => [:ead, :archdesc, :controlaccess, :subject_a], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable])
        # Rights (collection-level, M)
        t.rights(:proxy => [:ead, :archdesc, :accessrestrict], :index_as=>[Descriptors.cleaned_displayable, :stored_searchable])
        # Type (M)
        t.type(:proxy => [:ead, :archdesc, :did, :physdesc, :type], :index_as=>[Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])

        # Specific terms for EAD (attributes of the EncodedArchivalDescription class)
        # Abstract
        t.abstract(:proxy => [:ead, :archdesc, :did,  :abstract], :index_as=>[Descriptors.cleaned_searchable])
        # Bioghist
        t.bioghist(:proxy => [:ead, :archdesc, :bioghist], :index_as=>[Descriptors.cleaned_searchable])
        # Scopecontent
        t.scope_content(:proxy => [:ead, :archdesc, :scopecontent], :index_as=>[Descriptors.cleaned_searchable])
        # Eadlevel
        t.ead_level(:proxy => [:ead, :archdesc, :ead_level])
        # Namecoverage
        t.name_coverage(:proxy => [:ead, :archdesc, :controlaccess, :name_coverage], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        # Physdesc
        t.physdesc(:proxy => [:ead, :archdesc, :did, :physdesc], :index_as=>[Descriptors.cleaned_searchable])
        # Dao
        t.dao(:proxy => [:ead, :archdesc, :did, :dao])
        # Dao_href
        t.dao_href(:proxy => [:ead, :archdesc, :did, :dao, :href])
        # Daodesc
        t.dao_desc(:proxy => [:ead, :archdesc, :did, :dao, :daodesc])
        # Type ead - repository
        t.type_ead(:proxy => [:ead, :archdesc, :ead_level])
        # Eadid
        #t.eadid(:proxy => [:ead, :eadheader, :eadid], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        # Unitid
        #t.unitid(:proxy => [:ead, :eadheader, :eadid], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        # Repositorycode
        t.repository_code(:proxy => [:ead, :eadheader, :eadid, :repository_code], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        # Countrycode
        t.country_code(:proxy => [:ead, :eadheader, :eadid, :country_code], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        # Identifier
        t.identifier(:proxy => [:ead, :eadheader, :eadid])
        t.identifier_id(:proxy => [:ead, :eadheader, :eadid, :identifier_attr])
        t.identifier_url(:proxy => [:ead, :eadheader, :eadid, :url_attr])
        t.identifier_public_id(:proxy => [:ead, :eadheader, :eadid, :public_id_attr])

        # DRI ELEMENTS with multiple mappings
        # Language
        t.language_did(:proxy => [:ead, :archdesc, :did, :langmaterial, :language], :index_as=>[Descriptors.cleaned_searchable, Descriptors.language_facetable])
        # Creation_Date
        t.creation_date_profiledesc(:proxy => [:ead, :eadheader, :profiledesc, :creation, :date], :index_as=>[Descriptors.cleaned_searchable])
        # License
        t.user_restrict(:proxy => [:ead, :archdesc, :userestrict], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        # Subject
        t.subject_archdesc(:proxy => [:ead, :archdesc, :subject_b], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable])

        # FIXME The proxies below do not have an attribute in the EncodedArchivalDescription class
        # EAD coverage elements within control access headings, authority-controlled search across finding aids
        t.persname_coverage(:proxy => [:ead, :archdesc, :controlaccess, :persname_coverage], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.corpname_coverage(:proxy => [:ead, :archdesc, :controlaccess, :corpname_coverage], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.geographical_coverage(:proxy => [:ead, :archdesc, :controlaccess, :geographical_coverage], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.temporal_coverage(:path => 'unitdate[not(@datechar="Creation")]', :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        # EAD Elements
        t.note(:proxy => [:ead, :eadheader, :filedesc, :notestmt, :note], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
      end # set_terminology

      # synchronize_metadata_on_save
      # Currently, it is only used in EAD. Likely to be used in MODS too.
      def synchronize_metadata_on_save
        @synchronize_metadata_on_save || true
      end

      # When working with EAD documents using namespaces and schema-based
      #def from_xml(xml=nil)
      #  if xml.nil?
      #  # noop: handled in #ng_xml accessor.. tmpl.ng_xml = self.xml_template
      #  elsif xml.kind_of? Nokogiri::XML::Node
      #    self.ng_xml = xml.remove_namespaces!
      #  else
      #    self.ng_xml = Nokogiri::XML::Document.parse(xml).remove_namespaces!
      #  end
      #end

      # Build the xml doc
      def self.xml_template
        builder = Nokogiri::XML::Builder.new do |xml|
          # Updated EAD to use XSD as opposed to DTD
          #xml.doc.create_internal_subset(
          #    'ead',
          #    "+//ISBN 1-931666-00-8//DTD ead.dtd (Encoded Archival Description (EAD) Version 2002)//EN",
          #    ""
          #)
          xml.ead("xmlns:xlink"=>"http://www.w3.org/1999/xlink",
                  "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
                  "xmlns:ead"=>"urn:isbn:1-931666-22-9",
                  "xsi:schemaLocation"=>"http://www.loc.gov/ead ead.xsd") {
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
      end #xml_template

      def to_solr(solr_doc=Hash.new)
        solr_doc = super(solr_doc)

        # Title_sorted - A SOLR index for sorting titles
        if (title.length > 0)

          sorted_title = DRI::Metadata::Transformations.transform_title_for_sort(title[0])

          if (sorted_title != "")
            solr_doc.merge!(Solrizer.solr_name('title_sorted', :stored_sortable, type: :string) => [sorted_title])
          end
        end

        # Type
        solr_doc.merge!(Solrizer.solr_name('type', :stored_searchable) => type)
        solr_doc.merge!(Solrizer.solr_name('type', :facetable) => type)

        # EAD has several "name" tags, so we merge them together into the SOLR document
        person_array = person_array_for_index()

        solr_doc.merge!(Solrizer.solr_name('person', :facetable) => person_array)
        solr_doc.merge!(Solrizer.solr_name('person', :stored_searchable, type: :text) => person_array | DRI::Metadata::Transformations.transform_name(person_array))

        # all_metadata - A SOLR index of all the text contained in the XML document
        all_metadata = ""
        ng_xml.xpath("//text()").each do |text_node|
          all_metadata += text_node.text
          all_metadata += " "
        end
        solr_doc.merge!(Solrizer.solr_name("all_metadata", :stored_searchable, type: :text) => [all_metadata])

        description_array = description_for_index()

        # FIXME Need to check what, and how to index, Solr fields
        # solr_doc.merge!(ActiveFedora::SolrService.solr_name('description', :stored_searchable, type: :string) => description_array)

        # Subject
        subject_array = subject_for_index()

        solr_doc.merge!(Solrizer.solr_name('subject', :stored_searchable) => subject_array)
        solr_doc.merge!(Solrizer.solr_name('subject', :facetable) => subject_array)

        # Published Date
        solr_doc.merge!(Solrizer.solr_name('published_date', :stored_searchable) => creation_date_profiledesc | published_date)

        # Licence
        solr_doc.merge!(ActiveFedora::SolrService.solr_name('licence', :stored_searchable, type: :string) => user_restrict) unless user_restrict == []

        solr_doc
      end #solr_doc

      # Index Helper Methods
      def person_array_for_index()
        return name_coverage | persname_coverage | corpname_coverage | creator
      end

      def language_for_index()
        return language | language_did
      end
      # Mapping to UI description attribute from EAD: scopecontent, abstract, bioghist, daodesc
      def description_for_index()
        return description | abstract | bioghist | dao_desc | note
      end

      # Mapping to UI Rights / License ? userestrict or accessrestrict
      def rights_for_index()
        return rights | user_restrict
      end

      # Mapping to UI subjects: controlaccess/subject or subject
      def subject_for_index()
        return subject | subject_archdesc
      end

      # Helpers for getting elements with multiple mappings
      def get_language()
        (language != []) ? language : language_did
      end

      def get_description()
        return description unless description == []
        return abstract unless description_abstract == []
        return bioghist unless description_bioghist ==[]
        return dao_desc unless description_daodesc == []
        # Added also note from the eadHeader
        return note unless note == []
        []
      end

      def get_creation_date()
        return creation_date unless creation_date == []
        return creation_date_profiledesc unless creation_date_profiledesc == []
        []
      end

      def get_rights()
        (rights != []) ? rights : user_restrict
      end

      def get_subject()
        (subject != []) ? subject : subject_archdesc
      end

      def metadata_path field
        case field
          when :title
            [:ead, :eadheader, :filedesc, :titlestmt, :title]
          when :description, :scope_content
            [:ead, :archdesc, :scopecontent]
          when :abstract
            [:ead, :archdesc, :did, :abstract]
          when :bioghist
            [:ead, :archdesc, :bioghist]
          when :ead_level, :type_ead
            [:ead, :archdesc, :ead_level]
          when :language
            [:ead, :eadheader, :profiledesc, :langusage, :language]
          when :language_did
            [:ead, :archdesc, :did, :langmaterial, :language]
          when :creator
            [:ead, :archdesc, :did, :creator]
          when :contributor
            [:ead, :archdesc, :did, :origination, :contributor]
          when :publisher
            [:ead, :eadheader, :filedesc, :publicationstmt, :publisher]
          when :creation_date
            [:creation_date]
          when :creation_date_profiledesc
            [:ead, :eadheader, :profiledesc, :creation, :date]
          when :published_date
            [:ead, :eadheader, :filedesc, :publicationstmt, :date]
          when :name_coverage
            [:ead, :archdesc,  :name_coverage]
          when :geographical_coverage
            [:ead, :archdesc, :geographical_coverage]
          when :corpname_coverage
            [:ead, :archdesc, :controlaccess, :corpname_coverage]
          when :persname_coverage
            [:ead, :archdesc, :controlaccess, :persname_coverage]
          when :physdesc
            [:ead, :archdesc, :did, :physdesc]
          when :type
            [:ead, :archdesc, :did, :physdesc, :type]
          #when :type_ead
          #  "archival finding aid"
          when :dao
            [:ead, :archdesc, :did, :dao]
          when :dao_href
            [:ead, :archdesc, :did, :dao, :href]
          when :dao_desc
            [:ead, :archdesc, :did, :dao, :daodesc]
          when :identifier
            [:ead, :eadheader, :eadid]
          when :identifier_id
            [:ead, :eadheader, :eadid, :identifier_attr]
          when :identifier_url
            [:ead, :eadheader, :eadid, :url_attr]
          when :identifier_public_id
            [:ead, :eadheader, :eadid, :public_id_attr]
          when :repository_code
            [:ead, :eadheader, :eadid, :repository_code]
          when :country_code
            [:ead, :eadheader, :eadid, :country_code]
          when :rights
            [:ead, :archdesc, :accessrestrict]
          when :user_restrict
            [:ead, :archdesc, :userestrict]
          when :subject
            [:ead, :archdesc, :controlaccess, :subject_a]
          when :subject_archdesc
            [:ead, :archdesc, :subject_b]
          when :note
            [:ead, :eadheader, :filedesc, :notestmt, :note]
          else
            []
        end
      end #metadata_path

      def interchangeable?
        false
      end

      def collection?
        true
      end

      # DRI Mandatory elements + EAD LC best practices
      def custom_validations
        errors = Hash.new

        # Mandatory elements at collection-level
        title_result = false
        description_result = false
        creator_result = false
        rights_result = false

        # EAD-specific validation from best practices
        ead_id_result = false
        cc_result = false
        rc_result = false
        ead_level_result = false

        # Changed to use the proxies for consistency
        # Title
        title.each do |curr_title|
          title_result = true unless curr_title.blank?
        end
        # Description
        description_for_index().each do |curr_description|
          description_result = true unless curr_description.blank?
        end
        # Creator
        creator.each do |curr_creator|
          creator_result = true unless curr_creator.blank?
        end
        # Rights
        rights_for_index().each do |curr_r|
          rights_result = true unless curr_r.blank?
        end

        # EAD-specific
        ead_level.each do |curr_ead_level|
          ead_level_result = true unless curr_ead_level.blank?
        end

        identifier.each do |curr_ead_id|
          if (!curr_ead_id.blank? &&
          (!identifier_id.blank? ||
          !identifier_url.blank? ||
          !identifier_public_id.blank?))
            ead_id_result = true
          end
          #ead_id_result = true unless curr_ead_id.blank?
        end

        country_code.each do |curr_cc|
          cc_result = true unless curr_cc.blank?
        end

        repository_code.each do |curr_rc|
          rc_result = true unless curr_rc.blank?
        end

        # DRI Compulsory elements
        errors[:title] = "can't be blank" if title_result == false
        errors[:description] = "can't be blank" if description_result == false
        errors[:creator] = "can't be blank" if creator_result == false
        errors[:rights] = "can't be blank" if rights_result == false
        # errors[:abstract] = "can't be blank" if description_result == false

        # Specific EAD validation
        errors[:ead_level] = "can't be blank" if ead_level_result == false
        # For validation of unitid or eadid we now use identifier
        # For EAD header maps to eadid and for components maps to unitid
        errors[:identifier] = "can't be blank" if ead_id_result == false
        errors[:country_code] = "can't be blank" if cc_result == false
        errors[:repository_code] = "can't be blank" if rc_result == false

        # errors[:ead_id] = "can't be blank" if ead_id_result == false

        errors
      end #custom_validations

    end #class

  end #module

end #module
