module DRI

  module Metadata

    class EncodedArchivalDescription < DRI::Metadata::Base

      # OM (Opinionated Metadata) terminology mapping to an EAD Collection
      set_terminology do |t|
        t.root(:path => "ead", :namespace_prefix => nil)
        # Elements that can occur nested within other elements: multiple options
        t.p(:path => "p", :namespace_prefix => nil)
        # They can be used as subjects or even in the title
        t.geographic_name(:path => "geogname[not(@role='subject')]") {
          t.role(:path => {:attribute => "role"})
        }
        t.name_(:path => "name[not(@role='subject')]") {
          t.role(:path => {:attribute => "role"})
        }
        t.persname_(:path => "persname[not(parent::origination[@label='Creator:']) and not(@role='creator') and not(@role='cre') and not(@role='aut') and not(@role='subject')]") {
          t.role(:path => {:attribute => "role"})
        }
        t.corpname_(:path => "corpname[not(@role='subject')]") {
          t.role(:path => {:attribute => "role"})
        }
        t.famname_(:path => "famname[not(@role='subject')]") {
          t.role(:path => {:attribute => "role"})
        }

        t.date_(:path => "date[not(parent::creation) and not(parent::publicationstmt)]") {
          t.normal(:path => {:attribute => "normal"}, :namespace_prefix => nil)
          t.type(:path => {:attribute => "type"}, :namespace_prefix => nil)
        }

        t.date_text(:ref => [:date], :attributes => {"normal" => :none})

        t.subject_anywhere(:path => "subject")


        t.eadheader {
          # We need to keep track of the unitid in order to sync this XML snippet to the correct
          # component tag in the complete EAD XML datastream in the collection object!
          t.eadid(:path => "eadid", :namespace_prefix => nil) {
            # EAD Standard note: for eadid the mandatory attributes are mainagencycode and countrycode
            # We map t.repository_code to mainagencycode since this is the one needed and to reuse the term with
            # ead components (the ead class attribute needed is only repository_code)
            t.repository_code(:path => {:attribute => "mainagencycode"}, :namespace_prefix => nil)
            t.country_code(:path => {:attribute => "countrycode"}, :namespace_prefix => nil)
            t.identifier_attr(:path => {:attribute => "identifier"}, :namespace_prefix => nil)
            t.url_attr(:path => {:attribute => "url"}, :namespace_prefix => nil)
            t.public_id_attr(:path => {:attribute => "publicid"}, :namespace_prefix => nil)
          }
          t.filedesc {
            t.titlestmt {
              t.title(:path => "titleproper")
            }
            t.publicationstmt {
              t.p_(:ref => [:p])
              t.publisher()
              t.date_(:path => "date")
            }
            # Also added from recommendation
            t.notestmt {
              t.note {
                t.p_(:ref => [:p])
              }
            }
          }
          t.profiledesc {
            # Collection creation_date
            t.creation {
              t.date_(:ref => [:date])
            }
            # Language within eadheader
            t.langusage {
              t.language(:path => "language", :namespace_prefix => nil) {
                t.langcode_attr(:path => {:attribute => "langcode"}, :namespace_prefix => nil)
              }
            }
          }
        }
        t.archdesc {
          t.scopecontent {
            t.head
            t.p_(:ref => [:p])
          }
          # Subject can be
          t.controlaccess {
            t.head
            t.p_(:ref => [:p])
            # Preferred subject from the guidelines
            t.subject_a(:path => "subject")
            # Name, Personal, Corporate Name
            t.name_subject(:path => "name", :attributes => {:role => "subject"})
            t.persname_subject(:path => "persname", :attributes => {:role => "subject"})
            t.corpname_subject(:path => "corpname", :attributes => {:role => "subject"})
            t.famname_subject(:path => "famname", :attributes => {:role => "subject"})
            # Geographical coverage
            t.geographical_subject(:path => "geogname", :attributes => {:role => "subject"})
          }
          t.subject_b(:path => "subject")

          t.name_archdesc(:ref => [:name])
          t.persname_archdesc(:ref => [:persname])
          t.corpname_archdesc(:ref => [:corpname])
          t.geographical_archdesc(:ref => [:geographic_name])
          t.ead_level(:path => {:attribute => "level"}, :namespace_prefix => nil)
          t.other(:path => {:attribute => "otherlevel"}, :namespace_prefix => nil)
          t.did(:path => "did", :namespace_prefix => nil) {
            t.unit_title(:path => "unittitle", :namespace_prefix => nil) {
              t.geographical_title(:ref => [:geographic_name])
            }
            t.abstract
            # TODO Decide the preference order for language: within eadheader or within did
            # Language within did
            t.langmaterial {
              t.language(:path => "language", :namespace_prefix => nil) {
                t.langcode_attr(:path => {:attribute => "langcode"}, :namespace_prefix => nil)
              }
            }
            # FIXME Creator in NIVAL uses label="Creator:"
            t.creator(:path => "origination")

            t.origination(:path => "origination") {
              t.contributor(:path => "persname", :attributes => {:role => "contributor"}, :namespace_prefix => nil)
            }

            t.unitdate(:path => "unitdate") {
              t.normal(:path => {:attribute => "normal"}, :namespace_prefix => nil)
              t.datechar(:path => {:attribute => "datechar"}, :namespace_prefix => nil)
            }
            t.physdesc(:path => "physdesc") {
              t.type(:path => "genreform")
            }
            t.dao(:path => "dao") {
              t.href(:path => {:attribute => "href"})
              t.daodesc {
                t.p_(:ref => [:p])
              }
            }
            t.repository {
              t.p_(:ref => [:p])
              t.corpname {
                t.p_(:ref => [:p])
              }
            }
          }
          # DAO can also appear within <archdesc> directly
          t.dao(:path => "dao") {
            t.href(:path => {:attribute => "href"})
            t.daodesc {
              t.p_(:ref => [:p])
            }
          }
          t.bioghist {
            t.p_(:ref => [:p])
          }
          # Rights either userestrict or accessrestrict
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
        # Proxies for the DRI fields
        # Title (collection-level, M)
        t.title(:proxy => [:ead, :archdesc, :did, :unit_title], :index_as => [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        # Description (collection-level, M)
        t.description(:path => "/ead/archdesc/scopecontent/p | /ead/archdesc[not(scopecontent)]/did/abstract | /ead/archdesc[not(scopecontent) and not(did/abstract)]/bioghist/p", :index_as => [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        # Language //archdesc/did/langmaterial/language (collection-level, R best practice) but for NIVAL... use langusage in the eadHeader
        t.language(:proxy => [:ead, :eadheader, :profiledesc, :langusage, :language], :index_as => [Descriptors.cleaned_searchable, Descriptors.language_facetable])
        # Creator (collection-level, M)
        t.creator(:proxy => [:ead, :archdesc, :did, :creator], :index_as => [Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable, :sortable])
        # Contributor (R)
        t.contributor(:proxy => [:ead, :archdesc, :did, :origination, :contributor], :index_as => [Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable, :sortable])
        # Publisher (collection-level, DRI pre-populated)
        t.publisher(:proxy => [:ead, :eadheader, :filedesc, :publicationstmt, :publisher], :index_as => [Descriptors.cleaned_searchable, :sortable])
        # Published Date (collection-level, DRI pre-populated)
        # TODO Add published_date field to the terminology. What's the mapped EAD term?
        t.published_date(:path => "ead/eadheader/filedesc/publicationstmt/date", :attributes => {"normal" => :none})
        # Creation Date, now with generic xpath query: @datechar="creation" case-insensitive
        t.creation_date(:path => 'unitdate[@datechar[contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "creation")] and not(@normal)]')
        # Rights (collection-level, M) From the guidelines, at collection-level maps to userestrict
        t.rights(:proxy => [:ead, :archdesc, :userestrict, :p], :index_as => [Descriptors.cleaned_displayable, :stored_searchable])
        # Type (M)
        t.type(:proxy => [:ead, :archdesc, :did, :physdesc, :type], :index_as => [Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])

        # Subject (collection-level, R) - From LoC To indicate a subject with major representation in the materials being described, nest <subject> within the <controlaccess> element
        t.subject(:proxy => [:ead, :archdesc, :controlaccess, :subject_a], :index_as => [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable])
        # Subjects (including names, persnames, corpnames and famnames with @role='subject', nested within <controlaccess>)
        t.subject_archdesc(:proxy => [:ead, :archdesc, :subject_b], :index_as => [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable])
        t.name_subject(:proxy => [:ead, :archdesc, :controlaccess, :name_subject], :index_as => [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable])
        t.persname_subject(:proxy => [:ead, :archdesc, :controlaccess, :persname_subject], :index_as => [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.corpname_subject(:proxy => [:ead, :archdesc, :controlaccess, :corpname_subject], :index_as => [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.famname_subject(:proxy => [:ead, :archdesc, :controlaccess, :famname_subject], :index_as => [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.geographical_subject(:proxy => [:ead, :archdesc, :controlaccess, :geographical_subject], :index_as => [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])

        # Specific terms for EAD (attributes of the EncodedArchivalDescription class)
        # Abstract
        t.abstract(:proxy => [:ead, :archdesc, :did, :abstract], :index_as => [Descriptors.cleaned_searchable])
        # Bioghist
        t.bioghist(:proxy => [:ead, :archdesc, :bioghist, :p], :index_as => [Descriptors.cleaned_searchable])
        # Scopecontent
        t.scope_content(:proxy => [:ead, :archdesc, :scopecontent], :index_as => [Descriptors.cleaned_searchable])
        # Eadlevel
        t.ead_level(:proxy => [:ead, :archdesc, :ead_level])
        # Eadlevel - otherlevel
        t.ead_level_other(:proxy => [:ead, :archdesc, :other])
        # Physdesc
        t.physdesc(:proxy => [:ead, :archdesc, :did, :physdesc], :index_as => [Descriptors.cleaned_searchable])
        # Dao
        t.dao(:proxy => [:ead, :archdesc, :did, :dao])
        # Dao_href
        t.dao_href(:proxy => [:ead, :archdesc, :did, :dao, :href])
        # Daodesc
        t.dao_desc(:proxy => [:ead, :archdesc, :did, :dao, :daodesc, :p])
        # Type ead - repository
        t.type_ead(:proxy => [:ead, :archdesc, :ead_level])

        # Compulsory attributes at finding aid level: identifier, repositorycode and countrycode, in <eadid>
        # Repositorycode
        t.repository_code(:proxy => [:ead, :eadheader, :eadid, :repository_code], :index_as => [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        # Countrycode
        t.country_code(:proxy => [:ead, :eadheader, :eadid, :country_code], :index_as => [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        # Identifier
        t.identifier(:proxy => [:ead, :eadheader, :eadid])
        t.identifier_id(:proxy => [:ead, :eadheader, :eadid, :identifier_attr])
        t.identifier_url(:proxy => [:ead, :eadheader, :eadid, :url_attr])
        t.identifier_public_id(:proxy => [:ead, :eadheader, :eadid, :public_id_attr])

        # DRI ELEMENTS with multiple mappings
        # Language
        t.language_did(:proxy => [:ead, :archdesc, :did, :langmaterial, :language], :index_as => [Descriptors.cleaned_searchable, Descriptors.language_facetable])
        # Creation_Date
        t.creation_date_profiledesc(:proxy => [:ead, :eadheader, :profiledesc, :creation, :date], :index_as => [Descriptors.cleaned_searchable])
        t.access_restrict(:proxy => [:ead, :archdesc, :accessrestrict, :p], :index_as => [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])

        # EAD coverage elements within control access headings, authority-controlled search across finding aids
        t.name_coverage(:proxy => [:name], :index_as => [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.persname_coverage(:proxy => [:persname], :index_as => [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.corpname_coverage(:proxy => [:corpname], :index_as => [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.famname_coverage(:proxy => [:famname], :index_as => [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.geographical_coverage(:proxy => [:geographic_name], :index_as => [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable])
        t.temporal_coverage(:path => 'unitdate[@datechar[not(contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "creation"))] and not(@normal)]')
        # EAD Elements
        t.note(:proxy => [:ead, :eadheader, :filedesc, :notestmt, :note], :index_as => [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])

        # Related Material
        t.related_material(:path => "extref/@href[ancestor::relatedmaterial]", :index_as => [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        # Alternative Form Available
        t.alternative_form(:path => "extref/@href[ancestor::altformavail]", :index_as => [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])

        t.creation_date_idx(:path => 'unitdate[@datechar[contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "creation")]]/@normal')
        t.creation_date_idx_d(:path => 'unitdate[@datechar[contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "creation")] and @normal]')
        t.published_date_idx(:path => 'ead/eadheader/filedesc/publicationstmt/date/@normal')
        t.published_date_idx_d(:path => 'ead/eadheader/filedesc/publicationstmt/date[@normal]')
        t.temporal_coverage_idx(:path => 'unitdate[@datechar[not(contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "creation")) and not(contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "publication"))]]/@normal')
        t.temporal_coverage_idx_d(:path => 'unitdate[@datechar[not(contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "creation")) and not(contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "publication"))] and @normal]')
        t.date_idx(:proxy => [:date, :normal])
        t.date_idx_d(:path => "date[not(parent::creation) and not(parent::publicationstmt) and @normal]")

        # Mapping to geogname supporting DCMI Point and Box
        t.geocode_point(:path => "geogname[not(@role='subject')]", :attributes => {"rules" => "dcterms:Point"})
        t.geocode_box(:path => "geogname[not(@role='subject')]", :attributes => {"rules" => "dcterms:Box"})
        # Mapping to geogname supporting Logaimn URIs
        t.geocode_logainm(:path => "geogname[not(@role='subject')]", :attributes => {"source" => "logainm"})

      end # set_terminology

      # synchronize_metadata_on_save
      def synchronize_metadata_on_save
        @synchronize_metadata_on_save || true
      end

      # Build the xml doc
      def self.xml_template
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.doc.create_internal_subset('ead', '+//ISBN 1-931666-00-8//DTD ead.dtd (Encoded Archival Description (EAD) Version 2002)//EN', '')
          xml.ead {
            xml.eadheader {
              xml.eadid # identifier
            }
            xml.archdesc('level' => 'fonds') { # ead_level
              xml.did {
                xml.unittitle # title
                xml.unitdate('datechar' => 'creation') # creation_date
                xml.unitdate('datechar' => 'coverage') # temporal_coverage
                xml.origination # creator
                xml.physdesc {
                  xml.genreform # type
                }
              }
              xml.scopecontent # description
              xml.userestrict # rights
              xml.controlaccess {
                xml.subject # subject
                xml.persname('role' => 'subject')
                xml.geogname('role' => 'subject')
              }
              xml.dsc
            }
          }
        end

        builder.doc
      end # xml_template

      #
      # @param solr_doc [Hash]
      # @return [Hash]
      def to_solr(solr_doc=Hash.new, opts = {})
        solr_doc = super(solr_doc)

        # Title_sorted - A SOLR index for sorting titles
        if (title.length > 0)
          sorted_title = DRI::Metadata::Transformations.transform_title_for_sort(title[0])

          if (sorted_title != "")
            solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('title_sorted', :stored_sortable, type: :string) => [sorted_title])
          end
        end

        # Type
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('type', :stored_searchable) => type)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('type', :facetable) => type)

        # EAD has several "name" tags, so we merge them together into the SOLR document
        person_array = person_array_for_index

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('person', :facetable) => person_array)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('person', :stored_searchable, type: :text) => person_array | DRI::Metadata::Transformations.transform_name(person_array))

        # all_metadata - A SOLR index of all the text contained in the XML document
        all_metadata = ''
        ng_xml.xpath('//text()').each do |text_node|
          all_metadata += text_node.text
          all_metadata += ' '
        end
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('all_metadata', :stored_searchable, type: :text) => [all_metadata])

        # Subject: generic, name and place
        subject_array = subject_for_index

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('subject', :stored_searchable) => subject_array)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('subject', :facetable) => subject_array)

        subject_name_array = subject_name_for_index
        subject_place_array = subject_place_for_index

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('name_coverage', :stored_searchable) => subject_name_array)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('name_coverage', :facetable) => subject_name_array)

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('geographical_coverage', :stored_searchable) => subject_place_array)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('geographical_coverage', :facetable) => subject_place_array)

        # Publisher
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('publisher', :stored_searchable) => publisher) unless publisher == []

        # Type
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('type', :stored_searchable, type: :string) => 'Collection')

        # Indexing dates for display + COOL date range

        # Display of Subject(Temporal)
        subject_temporal_array = subject_temporal_for_index
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('temporal_coverage', :stored_searchable) => subject_temporal_array)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('temporal_coverage', :facetable) => subject_temporal_array)
        # Display of Creation Date
        unless creation_date_idx == [] && creation_date == []
          cdate_array = creation_date.collect! do |value|
            DRI::Metadata::Transformations.create_dcmi_period(value)
          end
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('creation_date', :stored_searchable) => display_date_for_index(creation_date_idx, creation_date_idx_d) | cdate_array)
        end
        # Display of Published Date
        unless published_date_idx == [] && published_date == []
          pdate_array = published_date.collect! do |value|
            DRI::Metadata::Transformations.create_dcmi_period(value)
          end
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('published_date', :stored_searchable) => display_date_for_index(published_date_idx, published_date_idx_d) | pdate_array)
        end
        # Index date ranges
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('creation_date_idx', :stored_searchable) => creation_date_idx) unless creation_date_idx == []

        date_ranges = date_ranges_for_index() # ALL the date ranges

        # Creation date dateRange index
        cdate_ranges = date_ranges.select { |key, value| ['creation_date'].include?(key) }
        solr_doc.merge!(DRI::Metadata::Transformations::CREATION_DATE_RANGE_SOLR_FIELD => DRI::Metadata::Transformations::transform_date_ranges(cdate_ranges)) unless cdate_ranges == {}

        # Published date dateRange index
        pdate_ranges = date_ranges.select { |key, value| ['published_date'].include?(key) }
        solr_doc.merge!(DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_SOLR_FIELD => DRI::Metadata::Transformations::transform_date_ranges(pdate_ranges)) unless pdate_ranges == {}

        # Subject date dateRange index
        sdate_ranges = date_ranges.select { |key, value| ['subject_date'].include?(key) }
        solr_doc.merge!(DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_SOLR_FIELD => DRI::Metadata::Transformations::transform_date_ranges(sdate_ranges)) unless sdate_ranges == {}

        # Geospatial indexing
        # Index dcterms Point and Box data into geospatial Solr field (location_rpt)
        geospatial_hash = DRI::Metadata::Transformations.transform_geospatial({'geographical_coverage' => geocode_point | geocode_box})

        uris = geocode_logainm.select { |i| i[/\A#{URI::regexp(['http', 'https'])}\z/] }
        if uris.present?
          linked_data = DRI::Metadata::Transformations.transform_geospatial({'geographical_coverage' => uris})

          geospatial_hash[:coords].concat(linked_data[:coords])
          geospatial_hash[:name].concat(linked_data[:name])
          geospatial_hash[:json].concat(linked_data[:json])
        end

        solr_doc.merge!(DRI::Metadata::Transformations::GEOSPATIAL_SOLR_FIELD => geospatial_hash[:coords]) unless geospatial_hash[:coords].empty?
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name(DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD, :stored_searchable) => geospatial_hash[:name]) unless geospatial_hash[:name].empty?
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name(DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD, :facetable, type: :text) => geospatial_hash[:name]) unless geospatial_hash[:name].empty?
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('geojson', :stored_searchable, type: :symbol) => geospatial_hash[:json]) unless geospatial_hash[:json].empty?

        solr_doc
      end # solr_doc

      # Index Helper Methods

      def person_array_for_index
        return creator | persname | corpname | name | famname
      end

      def language_for_index
        return language | language_did
      end

      # Mapping to UI Rights / License ? userestrict or accessrestrict
      def rights_for_index
        rights != [] ? rights : []
      end

      # Mapping to UI subjects: controlaccess/subject or subject
      # These are generic subjects similar to dc:coverage
      def subject_for_index
        return subject | subject_archdesc | subject_anywhere | persname_subject | name_subject | corpname_subject | famname_subject | geographical_subject
      end

      # These are DRI Subject(Name)
      def subject_name_for_index
        # Format persname to include role
        persname_roles = persname.map.with_index { |n, idx| persname.role[idx].nil? ? n : (n + " (#{persname.role[idx]})") }
        name_roles = name.map.with_index { |n, idx| name.role[idx].nil? ? n : (n + " (#{name.role[idx]})") }
        corpname_roles = corpname.map.with_index { |n, idx| corpname.role[idx].nil? ? n : (n + " (#{corpname.role[idx]})") }
        famname_roles = famname.map.with_index { |n, idx| famname.role[idx].nil? ? n : (n + " (#{famname.role[idx]})") }

        return name_roles | persname_roles | corpname_roles | famname_roles
      end

      # These are DRI Subject(Place)
      def subject_place_for_index
        geo_roles = geographic_name.map.with_index { |n, idx| geographic_name.role[idx].nil? ? n : (n + " (#{geographic_name.role[idx]})") }

        return geo_roles
      end

      # These are DRI Subject(Temporal)
      def subject_temporal_for_index
        dtext_array = date_text.map { |value| DRI::Metadata::Transformations.create_dcmi_period(value) }
        tcoverage_array = temporal_coverage.map { |value| DRI::Metadata::Transformations.create_dcmi_period(value) }

        return display_date_for_index(temporal_coverage_idx, temporal_coverage_idx_d) |
            display_date_for_index(date_idx, date_idx_d) |
            tcoverage_array |
            dtext_array
      end

      # Return all date ranges formatted in the right format for indexing and single dates
      # Format: start_date/end_date (ISO8601)
      # @return Hash with all the dates present in the metadata to be indexed as date ranges
      def date_ranges_for_index
        dates_hash = Hash.new

        dates_hash["creation_date"] = creation_date_idx
        dates_hash["published_date"] = published_date_idx
        dates_hash["subject_date"] = temporal_coverage_idx | date_idx

        return dates_hash
      end

      def display_date_for_index(date_field, date_field_d)
        date_field.collect.with_index do |value, idx|
          begin
            # Date range in ISO8601 format: YYYYmmdd/YYYYmmdd
            if (value.include?('/'))
              range = value.split('/')
              sdate = ISO8601::DateTime.new(range[0]).strftime('%b %d, %Y') #start date
              edate = ISO8601::DateTime.new(range[1]).strftime('%b %d, %Y') #end date
              if idx <= (date_field_d.length - 1)
                DRI::Metadata::Transformations.create_dcmi_period(date_field_d[idx], range[0], range[1])
              else
                DRI::Metadata::Transformations.create_dcmi_period(sdate << ' - ' << edate, range[0], range[1])
              end
            else
              if idx <= (date_field_d.length - 1)
                DRI::Metadata::Transformations.create_dcmi_period(date_field_d[idx], value)
              else
                sdate = ISO8601::DateTime.new(value).strftime('%b %d, %Y')
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

      # def metadata_path(field)
      #   case field
      #     when :title
      #       [:ead, :eadheader, :filedesc, :titlestmt, :title]
      #     when :description, :scope_content
      #       [:ead, :archdesc, :scopecontent, :p]
      #     when :abstract
      #       [:ead, :archdesc, :did, :abstract]
      #     when :bioghist
      #       [:ead, :archdesc, :bioghist, :p]
      #     when :ead_level, :type_ead
      #       [:ead, :archdesc, :ead_level]
      #     when :ead_level_other
      #       [:ead, :archdesc, :other]
      #     when :language
      #       [:ead, :eadheader, :profiledesc, :langusage, :language]
      #     when :language_did
      #       [:ead, :archdesc, :did, :langmaterial, :language]
      #     when :creator
      #       [:ead, :archdesc, :did, :creator]
      #     when :contributor
      #       [:ead, :archdesc, :did, :origination, :contributor]
      #     when :publisher
      #       [:ead, :eadheader, :filedesc, :publicationstmt, :publisher]
      #     when :creation_date
      #       [:creation_date]
      #     when :published_date
      #       [:published_date]
      #     when :creation_date_profiledesc
      #       [:ead, :eadheader, :profiledesc, :creation, :date]
      #     when :name_coverage
      #       [:name]
      #     when :geographical_coverage
      #       [:geographic_name]
      #     when :corpname_coverage
      #       [:corpname]
      #     when :famname_coverage
      #       [:famname]
      #     when :persname_coverage
      #       [:persname]
      #     when :physdesc
      #       [:ead, :archdesc, :did, :physdesc]
      #     when :type
      #       [:ead, :archdesc, :did, :physdesc, :type]
      #     when :dao
      #       [:ead, :archdesc, :did, :dao]
      #     when :dao_href
      #       [:ead, :archdesc, :did, :dao, :href]
      #     when :dao_desc
      #       [:ead, :archdesc, :did, :dao, :daodesc, :p]
      #     when :identifier
      #       [:ead, :eadheader, :eadid]
      #     when :identifier_id
      #       [:ead, :eadheader, :eadid, :identifier_attr]
      #     when :identifier_url
      #       [:ead, :eadheader, :eadid, :url_attr]
      #     when :identifier_public_id
      #       [:ead, :eadheader, :eadid, :public_id_attr]
      #     when :repository_code
      #       [:ead, :eadheader, :eadid, :repository_code]
      #     when :country_code
      #       [:ead, :eadheader, :eadid, :country_code]
      #     when :rights, :licence
      #       [:ead, :archdesc, :userestrict, :p]
      #     when :access_restrict
      #       [:ead, :archdesc, :accessrestrict, :p]
      #     when :subject
      #       [:ead, :archdesc, :controlaccess, :subject_a]
      #     when :subject_archdesc
      #       [:ead, :archdesc, :subject_b]
      #     when :note
      #       [:ead, :eadheader, :filedesc, :notestmt, :note]
      #     when :institute
      #       [:ead, :archdesc, :did, :repository, :corpname]
      #     when :related_material
      #       [:ead, :archdesc, :related_material, :p]
      #     when :alternative_form
      #       [:ead, :archdesc, :alternative_form, :p]
      #     else
      #       []
      #   end
      # end #metadata_path

      #def interchangeable?
      #  false
      #end

      def collection?
        true
      end

      # DRI Mandatory elements + EAD LoC best practices
      def custom_validations
        errors = Hash.new

        # Mandatory elements at collection-level
        title_result = false
        # Description, from MD Taskforce: either scopecontent or abstract; but at least one of them
        # Description maps to scopecontent by default and abstract to abstract
        description_result = false
        abstract_result = false
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
        # Description (scopecontent)
        description.each do |curr_description|
          description_result = true unless curr_description.blank?
        end
        # Abstract
        abstract.each do |curr_abstract|
          abstract_result = true unless curr_abstract.blank?
        end
        # Creator
        creator.each do |curr_creator|
          creator_result = true unless curr_creator.blank?
        end
        # Rights
        rights.each do |curr_r|
          rights_result = true unless curr_r.blank?
        end

        # EAD-specific
        ead_level.each do |curr_ead_level|
          ead_level_result = true unless curr_ead_level.blank?
        end

        # Identifier validation
        identifier.each do |curr_ead_id|
          ead_id_result = true unless curr_ead_id.blank?
          # the validation above is commented now because it is only an EAD recommendation
          #if (!curr_ead_id.blank? &&
          #(!identifier_id.blank? ||
          #!identifier_url.blank? ||
          #!identifier_public_id.blank?))
          #  ead_id_result = true
          #end
        end

        # Validation for eadid, @countrycode is a mandatory attribute for eadid element
        country_code.each do |curr_cc|
          cc_result = true unless curr_cc.blank?
        end

        # Validation for eadid, @mainagencycode (repository_code here) is mandatory for eadid element
        repository_code.each do |curr_rc|
          rc_result = true unless curr_rc.blank?
        end

        # TODO Should we add validation for creation date?

        # DRI Compulsory elements
        errors[:title] = "can't be blank" if title_result == false
        errors[:description] = "can't be blank" if (description_result == false && abstract_result == false)
        errors[:creator] = "can't be blank" if creator_result == false
        errors[:rights] = "can't be blank" if rights_result == false
        # errors[:abstract] = "can't be blank" if description_result == false

        # Specific EAD validation
        errors[:ead_level] = "can't be blank" if ead_level_result == false

        # EADID validation
        # 1. eadid must be present
        # 1.1 the attribute mainagencycode is compulsory for eadid
        # 1.2 the attribute countrycode is compulsory for eadid
        if (ead_id_result == false)
          errors[:identifier] = "can't be blank"
        elsif (cc_result == false || rc_result == false)
          errors[:identifier] = "invalid use"
          errors[:country_code] = "can't be blank" if cc_result == false
          errors[:repository_code] = "can't be blank" if rc_result == false
        end
        # errors[:ead_id] = "can't be blank" if ead_id_result == false

        errors
      end #custom_validations

    end #class

  end #module

end #module
