module DRI
  module Metadata
    class EncodedArchivalDescription < DRI::Metadata::Base
      # OM (Opinionated Metadata) terminology mapping to an EAD Collection
      set_terminology do |t|
        t.root(path: 'ead', namespace_prefix: nil)

        # Subject name, temporal and geographical terms
        t.geog_name(path: 'geogname') {
          t.role(path: { attribute: 'role' })
        }
        t.geog_name_cvg(ref: :geog_name, path: 'geogname[not(@role="subject")]')

        t.name {
          t.role(path: { attribute: 'role' })
        }
        t.name_cvg(ref: :name, path: 'name[not(parent::origination) and not(@role="subject")]')

        t.pers_name(path: 'persname') {
          t.role(path: { attribute: 'role' })
        }
        t.pers_name_cvg(ref: :pers_name, path: 'persname[not(parent::origination) and not(@role="subject")]')

        t.corp_name(path: 'corpname') {
          t.role(path: { attribute: 'role' })
        }
        t.corp_name_cvg(ref: :corp_name, path: 'corpname[not(parent::origination) and not(@role="subject")]')

        t.fam_name(path: 'famname') {
          t.role(path: { attribute: 'role' })
        }
        t.fam_name_cvg(ref: :fam_name, path: 'famname[not(parent::origination) and not(@role="subject")]')

        t.date {
          t.normal_at(path: { attribute: 'normal' })
          t.type_at(path: { attribute: 'type' })
        }
        t.date_cvg(ref: :date, path: 'date[not(parent::creation) and not(parent::publicationstmt)]')
        t.date_text(ref: :date, attributes: { normal: :none })

        t.lang(path: 'language') {
          t.langcode_at(path: { attribute: 'langcode' })
        }

        t.subject_anywhere(path: 'subject')

        t.ext_ref(path: 'extref') {
          t.href_at(path: { attribute: 'href' })
        }

        # EAD p
        t.p(path: 'p')

        t.ext_ref_p(path:'p') {
          t.ext_ref(ref: [:ext_ref])
        }

        # EAD HEADER elements
        t.ead_id(path: 'eadid') {
          # EAD Standard note: for eadid the mandatory attributes are mainagencycode and countrycode
          # We map t.repository_code to mainagencycode since this is the one needed and to reuse the term with
          # ead components (the ead class attribute needed is only repository_code)
          t.repository_code_at(path: { attribute: 'mainagencycode' })
          t.country_code_at(path: { attribute: 'countrycode' })
          t.identifier_at(path: { attribute: 'identifier' })
          t.url_at(path: { attribute: 'url' })
          t.public_id_at(path: { attribute: 'publicid' })
        }

        t.title_stmt(path: 'titlestmt') {
          t.title_proper(path: 'titleproper')
        }
        t.publication_stmt(path: 'publicationstmt') {
          t.p(ref: [:p])
          t.publisher
          t.date(ref: [:date])
          t.date_display(ref: [:date_text])
        }

        t.file_desc(path: 'filedesc') {
          t.title_stmt(ref: :title_stmt)
          t.publication_stmt(ref: :publication_stmt)
        }

        t.ead_header(path: 'eadheader') {
          t.ead_id(ref: [:ead_id])
          t.file_desc(ref: [:file_desc])
        }

        # ARCH DESC elements
        t.scope_content(path: 'scopecontent') {
          t.p(ref: [:p])
        }
        # Key subjects under controlaccess
        t.control_access(path: 'controlaccess') {
          # Preferred subject from the guidelines
          t.subject(ref: [:subject_anywhere])
          # Name, Personal name, Family name, Corporate Name, Geographical name
          t.name(ref: [:name], attributes: { role: 'subject' })
          t.pers_name(ref: [:pers_name], attributes: { role: 'subject' })
          t.corp_name(ref: [:corp_name], attributes: { role: 'subject' })
          t.fam_name(ref: [:fam_name], attributes: { role: 'subject' })
          t.geog_name(ref: [:geog_name], attributes: { role: 'subject' })
          t.name_cvg(ref: [:name_cvg])
          t.pers_name_cvg(ref: [:pers_name_cvg])
          t.corp_name_cvg(ref: [:corp_name_cvg])
          t.fam_name_cvg(ref: [:fam_name_cvg])
          t.geog_name_cvg(ref: [:geog_name_cvg])
        }
        # did
        t.lang_material(path: 'langmaterial') {
          t.lang(ref: [:lang])
        }
        t.origination {
          t.person_contributor(ref: [:pers_name], attributes: { role: 'contributor' })
          t.person_creator(ref: [:pers_name], attributes: { role: 'creator' })
          t.pers_name(ref: [:pers_name])
          t.name(ref: [:name])
          t.corp_name(ref: [:corp_name])
          t.fam_name(ref: [:fam_name])
        }

        t.unit_date(path: 'unitdate') {
          t.normal_at(path: { attribute: 'normal' })
          t.datechar_at(path: { attribute: 'datechar' })
        }
        t.unit_date_display(ref: :unit_date, attributes: { normal: :none })
        t.unit_date_other(ref: :unit_date, path: 'unitdate[@datechar[not(contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "creation")) and not(contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "publication"))]]')

        t.phys_desc(path: 'physdesc') {
          t.genre_form(path: 'genreform')
        }
        t.dao_desc {
          t.p(ref: [:p])
        }
        t.dao {
          t.href_at(path: { attribute: 'href' })
          t.dao_desc(ref: [:dao_desc], path: 'daodesc')
        }

        t.use_restrict(path: 'userestrict') {
          t.p(ref: [:p])
        }

        t.rel_mat(path: 'relatedmaterial') {
          t.p(ref: [:p])
          t.ext_ref(ref: [:ext_ref])
        }

        t.alt_form(path: 'altformavail') {
          t.p(ref: [:p])
          t.ext_ref_p(ref: [:ext_ref_p])
        }

        t.did {
          t.unit_title(path: 'unittitle')
          t.unit_date(ref: [:unit_date])
          t.unitdate_creation(ref: [:unit_date], path: 'unitdate[@datechar[contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "creation")]]')
          t.unit_date_other(ref: [:unit_date_other])
          t.origination(ref: [:origination])
          t.abstract
          t.lang_material(ref: [:lang_material])
          t.dao(ref: [:dao])
          t.phys_desc(ref: [:phys_desc])
        }

        t.biog_hist(path: 'bioghist') {
          t.p(ref: [:p])
        }

        t.arch_desc(path: 'archdesc') {
          # level attributes
          t.ead_level_at(path: { attribute: 'level' })
          t.other_level_at(path: { attribute: 'otherlevel' })

          t.control_access(ref: [:control_access])

          t.subject(ref: [:subject_anywhere])

          t.name(ref: [:name_cvg])
          t.pers_name(ref: [:pers_name_cvg])
          t.corp_name(ref: [:corp_name_cvg])
          t.fam_name(ref: [:fam_name_cvg])
          t.geog_name(ref: [:geog_name_cvg])

          t.did(ref: [:did])
          t.scope_content(ref: [:scope_content])
          # DAO can also appear within <archdesc> directly
          t.dao(ref: [:dao])
          t.biog_hist(ref: [:biog_hist])
          t.use_restrict(ref: [:use_restrict])
          t.rel_mat(ref: [:rel_mat])
          t.alt_form(ref: [:alt_form])
          t.phys_desc(ref: [:phys_desc])
          t.dsc
        }

        # DRI mandatory fields 1-to-1 mappings
        t.title(proxy: [:ead, :arch_desc, :did, :unit_title], index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.language(proxy: [:ead, :arch_desc, :did, :lang_material, :lang], index_as: [Descriptors.cleaned_searchable, Descriptors.language_facetable])
        t.contributor(proxy: [:ead, :arch_desc, :did, :origination, :person_contributor], index_as: [Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable, :sortable])
        t.publisher(proxy: [:ead, :ead_header, :file_desc, :publication_stmt, :publisher], index_as: [Descriptors.cleaned_searchable])
        t.rights(proxy: [:ead, :arch_desc, :use_restrict, :p], index_as: [Descriptors.cleaned_displayable, :stored_searchable])
        t.type(proxy: [:ead, :arch_desc, :did, :phys_desc, :genre_form], index_as: [Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.creation_date(proxy: [:ead, :arch_desc, :did, :unitdate_creation])
        t.published_date(proxy: [:ead, :ead_header, :file_desc, :publication_stmt, :date])
        t.subject(proxy: [:ead, :arch_desc, :control_access, :subject], index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable])

        t.description(path: '/ead/archdesc/scopecontent/p | /ead/archdesc[not(scopecontent)]/did/abstract | /ead/archdesc[not(scopecontent) and not(did/abstract)]/bioghist/p', index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.desc_abstract(proxy: [:ead, :arch_desc, :did, :abstract])
        t.desc_biog_hist(proxy: [:ead, :arch_desc, :biog_hist, :p])
        t.desc_scope_content(proxy: [:ead, :arch_desc, :scope_content, :p])
        t.desc_dao_desc(proxy: [:ead, :arch_desc, :did, :dao, :dao_desc, :p])

        t.creator(path: '/ead/archdesc/did/origination/*[(local-name()="name" or local-name()="persname" or local-name()="famname" or local-name()="corpname") and not(@role="contributor")]')
        t.creator_role(proxy: [:ead, :arch_desc, :did, :origination, :person_creator])
        t.creator_name(proxy: [:ead, :arch_desc, :did, :origination, :name])
        t.creator_persname(proxy: [:ead, :arch_desc, :did, :origination, :pers_name])
        t.creator_corpname(proxy: [:ead, :arch_desc, :did, :origination, :corp_name])
        t.creator_famname(proxy: [:ead, :arch_desc, :did, :origination, :fam_name])

        # Subjects (including names, persnames, corpnames and famnames with @role='subject', nested within <controlaccess>)
        t.subject_archdesc(proxy: [:ead, :arch_desc, :subject], index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable])
        t.name_subject(proxy: [:ead, :arch_desc, :control_access, :name], index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable])
        t.persname_subject(proxy: [:ead, :arch_desc, :control_access, :pers_name], index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable])
        t.corpname_subject(proxy: [:ead, :arch_desc, :control_access, :corp_name], index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable])
        t.famname_subject(proxy: [:ead, :arch_desc, :control_access, :fam_name], index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable])
        t.geogname_subject(proxy: [:ead, :arch_desc, :control_access, :geog_name], index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable])

        # Eadlevel
        t.ead_level(proxy: [:ead, :arch_desc, :ead_level_at], index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        # Eadlevel - otherlevel
        t.ead_level_other(proxy: [:ead, :arch_desc, :other_level_at], index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])

        # Dao
        t.dao_proxy(proxy: [:dao])
        t.dao_did(proxy: [:ead, :arch_desc, :did, :dao])
        t.dao_other(proxy: [:ead, :arch_desc, :dao])
        # Dao_href
        t.dao_href_proxy(proxy: [:dao, :href_at])
        # Daodesc
        t.dao_desc_proxy(proxy: [:dao, :dao_desc, :p])

        # Identifier
        t.identifier(proxy: [:ead, :ead_header, :ead_id])
        # Compulsory attributes at finding aid level: identifier, repositorycode and countrycode, in <eadid>
        t.identifier_id(proxy: [:ead, :ead_header, :ead_id, :identifier_at])
        # Repositorycode
        t.repository_code(proxy: [:ead, :ead_header, :ead_id, :repository_code_at])
        # Countrycode
        t.country_code(proxy: [:ead, :ead_header, :ead_id, :country_code_at])
        t.identifier_url(proxy: [:ead, :ead_header, :ead_id, :url_at])
        t.identifier_public_id(proxy: [:ead, :ead_header, :ead_id, :public_id_at])

        # EAD Elements
        # Related Material
        t.related_material(proxy: [:ead, :arch_desc, :rel_mat, :ext_ref, :href_at], index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        # Alternative Form Available
        t.alternative_form(proxy: [:ead, :arch_desc, :alt_form, :ext_ref_p, :ext_ref, :href_at], index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])

        # Mapping to geogname supporting DCMI Point and Box
        t.geocode_point(ref: :geog_name_cvg, attributes: { rules: 'dcterms:Point' })
        t.geocode_box(ref: :geog_name_cvg, attributes: { rules: 'dcterms:Box' })
        # Mapping to geogname supporting Logaimn URIs
        t.geocode_logainm(ref: :geog_name_cvg, attributes: { source: 'logainm' })

        # PROXIES FOR INDEXING
        # EAD coverage elements within control access headings, authority-controlled search across finding aids
        t.name_coverage(path: 'archdesc/controlaccess/*[(local-name()="name" or local-name()="persname" or local-name()="famname" or local-name()="corpname") and not(@role="subject")]')
        t.persname_coverage(proxy: [:ead, :arch_desc, :control_access, :pers_name_cvg])
        t.corpname_coverage(proxy: [:ead, :arch_desc, :control_access, :corp_name_cvg])
        t.famname_coverage(proxy: [:ead, :arch_desc, :control_access, :fam_name_cvg])
        t.geographical_coverage(proxy: [:geog_name_cvg])
        t.geogname_coverage_access(proxy: [:ead, :arch_desc, :control_access, :geog_name_cvg])
        t.temporal_coverage(proxy: [:did, :unit_date_other])

        t.creation_date_idx(path: 'unitdate[@datechar[contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "creation")]]/@normal')
        t.published_date_idx(path: 'ead/eadheader/filedesc/publicationstmt/date/@normal')
        t.temporal_coverage_idx(path: 'did/unitdate[@datechar[not(contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "creation")) and not(contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "publication"))]]/@normal')
        t.date_idx(proxy: [:date_cvg, :normal_at])
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
              xml.eadid(identifier: '', countrycode: 'IE', mainagencycode: '') # identifier
              xml.filedesc {
                xml.publicationstmt {
                  xml.date(normal: '') # published_date
                }
                xml.titlestmt {
                  xml.titleproper
                }
              }
            }
            xml.archdesc(level: 'fonds') { # ead_level
              xml.did {
                xml.unittitle # title
                xml.unitdate(datechar: 'creation') # creation_date
                xml.unitdate(datechar: 'coverage') # temporal_coverage
                xml.origination {
                  xml.persname(role: 'creator')
                  xml.persname(role: 'contributor')
                }
                xml.langmaterial {
                  xml.language(langcode: 'en')
                }
                xml.physdesc {
                  xml.genreform # type
                }
              }
              xml.scopecontent # description
              xml.userestrict # rights
              xml.controlaccess {
                xml.subject # subject
                xml.persname(role: 'subject')
                xml.geogname(role: 'subject')
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
      def to_solr(solr_doc = {}, opts = {})
        solr_doc = super(solr_doc, opts)

        # Title_sorted - A SOLR index for sorting titles
        if title.length > 0
          sorted_title = DRI::Metadata::Transformations.transform_title_for_sort(title[0])

          unless sorted_title.blank?
            solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('title_sorted', :stored_sortable, type: :string) => [sorted_title])
          end
        end

        # Type
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('type', :stored_searchable) => type)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('type', :facetable) => type)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('type', :stored_searchable, type: :string) => 'Collection')

        # EAD has several "name" tags, so we merge them together into the SOLR document
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('person', :facetable) => person_array_for_index)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('person', :stored_searchable, type: :text) => person_array_for_index | DRI::Metadata::Transformations.transform_name(person_array_for_index))

        # all_metadata - A SOLR index of all the text contained in the XML document
        all_metadata = ''
        ng_xml.xpath('//text()').each do |text_node|
          all_metadata += text_node.text
          all_metadata += ' '
        end
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('all_metadata', :stored_searchable, type: :text) => [all_metadata])

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('creator', :facetable) => creator_for_index)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('creator', :stored_searchable, type: :text) => creator_for_index)

        # Subject: generic, name and place
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('subject', :stored_searchable) => subject_for_index)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('subject', :facetable) => subject_for_index)

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('name_coverage', :stored_searchable) => subject_name_for_index)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('name_coverage', :facetable) => subject_name_for_index)

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('geographical_coverage', :stored_searchable) => subject_place_for_index)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('geographical_coverage', :facetable) => subject_place_for_index)

        # Publisher
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('publisher', :stored_searchable) => publisher) unless publisher == []

        # Indexing dates for display
        # Creation Date
        cdate_array = creation_date.collect.with_index do |value, idx|
          if creation_date(idx).normal_at.empty?
            DRI::Metadata::Transformations.create_dcmi_period(value)
          else
            iso_date = creation_date(idx).normal_at[0]
            iso_to_dcmi_period(value, iso_date)
          end
        end
        pdate_array = published_date.collect.with_index do |value, idx|
         if published_date(idx).normal_at.empty?
           DRI::Metadata::Transformations.create_dcmi_period(value)
         else
           iso_date = published_date(idx).normal_at[0]
           iso_to_dcmi_period(value, iso_date)
         end
        end
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('creation_date', :stored_searchable) => cdate_array) unless creation_date.empty?
        # Published Date
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('published_date', :stored_searchable) => pdate_array) unless published_date.empty?
        # Subject(Temporal)
        subject_temporal_array = subject_temporal_for_index
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('temporal_coverage', :stored_searchable) => subject_temporal_array)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('temporal_coverage', :facetable) => subject_temporal_array)

        #solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('creation_date_idx', :stored_searchable) => creation_date_idx) unless creation_date_idx == []

        # Index date ranges, and iso dates into the appropriate solr fields
        date_ranges = date_ranges_for_index # ALL the date ranges

        # Creation date dateRange index
        cdate_ranges = date_ranges.select { |key, _value| ['creation_date'].include?(key) }
        solr_doc.merge!(DRI::Metadata::Transformations::CREATION_DATE_RANGE_SOLR_FIELD => DRI::Metadata::Transformations::transform_date_ranges(cdate_ranges)) unless cdate_ranges.empty?

        # Indexing creation_date_idx is necessary for children, in case they inherit from the root collection
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('creation_date_idx', :stored_searchable) => creation_date_idx)

        # Published date dateRange index
        pdate_ranges = date_ranges.select { |key, _value| ['published_date'].include?(key) }
        solr_doc.merge!(DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_SOLR_FIELD => DRI::Metadata::Transformations::transform_date_ranges(pdate_ranges)) unless pdate_ranges.empty?

        # Subject date dateRange index
        sdate_ranges = date_ranges.select { |key, _value| ['subject_date'].include?(key) }
        solr_doc.merge!(DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_SOLR_FIELD => DRI::Metadata::Transformations::transform_date_ranges(sdate_ranges)) unless sdate_ranges.empty?

        # Geospatial indexing
        # Index dcterms Point and Box data into geospatial Solr field (location_rpt)
        geospatial_hash = DRI::Metadata::Transformations.transform_geospatial({ 'geographical_coverage' => geocode_point | geocode_box })

        uris = geocode_logainm.select { |i| i[/\A#{URI.regexp(['http', 'https'])}\z/] }
        if uris.present?
          linked_data = DRI::Metadata::Transformations.transform_geospatial({ 'geographical_coverage' => uris })

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

      def iso_to_dcmi_period(display, date)
        if date.include?('/')
          range = date.split('/')
          DRI::Metadata::Transformations.create_dcmi_period(display, range[0], range[1])
        else
          DRI::Metadata::Transformations.create_dcmi_period(display, date)
        end
      end

      def person_array_for_index
        creator | pers_name | corp_name | name | fam_name
      end

      def creator_for_index
        creators_array = []
        query = '/ead/archdesc/did/origination/*[not(@role="contributor")]'
        ng_xml.search(query).each { |n| creators_array << (n['role'].nil? ? n.content : "#{n.content} (#{n['role']})") }

        creators_array
      end

      # Mapping to UI subjects: controlaccess/subject or subject
      # These are generic subjects similar to dc:coverage
      def subject_for_index
        subject | subject_archdesc | subject_anywhere | persname_subject | name_subject | corpname_subject | famname_subject | geogname_subject
      end

      # These are DRI Subject(Name)
      def subject_name_for_index
        persname_roles = pers_name_cvg.map.with_index { |n, idx| pers_name_cvg(idx).role.empty? ? n : (n + " (#{pers_name_cvg(idx).role[0]})") }
        name_roles = name_cvg.map.with_index { |n, idx| name_cvg(idx).role.empty? ? n : (n + " (#{name_cvg(idx).role[0]})") }
        corpname_roles = corp_name_cvg.map.with_index { |n, idx| corp_name_cvg(idx).role.empty? ? n : (n + " (#{corp_name_cvg(idx).role[0]})") }
        famname_roles = fam_name_cvg.map.with_index { |n, idx| fam_name_cvg(idx).role.empty? ? n : (n + " (#{fam_name_cvg(idx).role[0]})") }

        name_roles | persname_roles | corpname_roles | famname_roles
      end

      # These are DRI Subject(Place)
      def subject_place_for_index
        geo_roles = geog_name_cvg.map.with_index { |n, idx| geog_name_cvg(idx).role.empty? ? n : (n + " (#{geog_name_cvg(idx).role[0]})") }

        geo_roles
      end

      # These are DRI Subject(Temporal)
      def subject_temporal_for_index
        date_array = date_cvg.collect.with_index do |value, idx|
          if date_cvg(idx).normal_at.empty?
            DRI::Metadata::Transformations.create_dcmi_period(value)
          else
            iso_date = date_cvg(idx).normal_at[0]
            iso_to_dcmi_period(value, iso_date)
          end
        end

        temporal_array = temporal_coverage.collect.with_index do |value, idx|
          if temporal_coverage(idx).normal_at.empty?
            DRI::Metadata::Transformations.create_dcmi_period(value)
          else
            iso_date = temporal_coverage(idx).normal_at[0]
            iso_to_dcmi_period(value, iso_date)
          end
        end

        temporal_array | date_array
      end

      # @note EAD date format: start/end [YYYYmmdd/YYYYmmdd | YYYY/YYYY]
      # Return all date ranges formatted in ISO8601 for indexing
      # @return Hash with all the dates present in the metadata to be indexed as date ranges
      def date_ranges_for_index
        dates_hash = {}

        dates_hash['creation_date'] = creation_date_idx unless creation_date_idx.empty?
        dates_hash['published_date'] = published_date_idx unless published_date_idx.empty?
        dates_hash['subject_date'] = temporal_coverage_idx | date_idx unless temporal_coverage_idx.empty? && date_idx.empty?

        dates_hash
      end

      def collection?
        true
      end

      def add_desc_scope_content(desc_array)
        ng_xml.search('/ead/archdesc/scopecontent').each(&:remove)

        archdesc_node = ng_xml.at('/ead/archdesc')
        sc = Nokogiri::XML::Node.new('scopecontent', ng_xml)
        desc_array.each do |desc|
          next if desc.empty?

          p = Nokogiri::XML::Node.new('p', ng_xml)
          p.content = desc
          sc.add_child(p)
        end
        archdesc_node.add_child(sc) unless sc.children.empty?
      end

      def add_desc_abstract(desc_array)
        ng_xml.search('/ead/archdesc/did/abstract').each(&:remove)

        did_node = ng_xml.at('/ead/archdesc/did')
        desc_array.each do |desc|
          next if desc.empty?

          abstract = Nokogiri::XML::Node.new('abstract', ng_xml)
          abstract.content = desc
          did_node.add_child(abstract)
        end
      end

      def add_desc_biog_hist(desc_array)
        ng_xml.search('/ead/archdesc/bioghist').each(&:remove)

        archdesc_node = ng_xml.at('/ead/archdesc')
        bh = Nokogiri::XML::Node.new('bioghist', ng_xml)
        desc_array.each do |desc|
          next if desc.empty?

          p = Nokogiri::XML::Node.new('p', ng_xml)
          p.content = desc
          bh.add_child(p)
        end
        archdesc_node.add_child(bh) unless bh.children.empty?
      end

      def add_creation_date(dates)
        return unless dates.is_a?(Hash)
        dates.symbolize_keys!
        valid_keys = [:display, :normal].all? { |s| dates.key? s }
        return unless valid_keys && dates[:display].size == dates[:normal].size

        ng_xml.search('/ead/archdesc/did/unitdate[@datechar[contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "creation")]]').each(&:remove)

        did_node = ng_xml.at('/ead/archdesc/did')
        dates[:display].each_with_index do |disp, idx|
          next if disp.empty?

          node = Nokogiri::XML::Node.new('unitdate', ng_xml)
          node.content = disp
          node[:datechar] = 'creation'
          node[:normal] = dates[:normal][idx] unless dates[:normal][idx].empty?
          did_node.add_child(node)
        end
      end

      def add_published_date(dates)
        return unless dates.is_a?(Hash)
        dates.symbolize_keys!
        valid_keys = [:display, :normal].all? { |s| dates.key? s }
        return unless valid_keys && dates[:display].size == dates[:normal].size

        ng_xml.search('/ead/eadheader/filedesc/publicationstmt/date').each(&:remove)

        pub_stmt = ng_xml.at('/ead/eadheader/filedesc/publicationstmt')
        if pub_stmt.nil?
          file_desc = ng_xml.at('/ead/eadheader/filedesc')
          pub_stmt = Nokogiri::XML::Node.new('publicationstmt', ng_xml)
          file_desc.add_child(pub_stmt)
        end
        dates[:display].each_with_index do |disp, idx|
          next if disp.empty?

          node = Nokogiri::XML::Node.new('date', ng_xml)
          node.content = disp
          node[:normal] = dates[:normal][idx] unless dates[:normal][idx].empty?
          pub_stmt.add_child(node)
        end
      end

      # Updates every person element under origination (creators)
      # @param creators [Hash] the attributes and content required to create a persname
      # @option :display [Array<String>] the content for the node
      # @option :role [Array<String>] the role attribute for the node
      # @option :tag [Array<String>] the name of the person tag to add
      def add_creator(creators)
        return unless creators.is_a?(Hash)
        creators.symbolize_keys!
        valid_keys = [:tag, :display, :role].all? { |s| creators.key? s }
        return unless valid_keys && creators[:display].size == creators[:role].size && creators[:role].size == creators[:tag].size

        ng_xml.search('/ead/archdesc/did/origination/*[(local-name()="name" or local-name()="persname" or local-name()="famname" or local-name()="corpname") and not(@role="contributor")]').each(&:remove)

        origination = ng_xml.at('/ead/archdesc/did/origination')
        if origination.nil?
          did_node = ng_xml.at('/ead/archdesc/did')
          origination = Nokogiri::XML::Node.new('origination', ng_xml)
          did_node.add_child(origination)
        end
        creators[:display].each_with_index do |disp, idx|
          next unless DRI::Vocabulary.ead_people_tags.include?(creators[:tag][idx])
          next if disp.empty?

          node = Nokogiri::XML::Node.new(creators[:tag][idx], ng_xml)
          node.content = disp
          node[:role] = creators[:role][idx] unless creators[:role][idx].empty?
          origination.add_child(node)
        end
      end

      def add_contributor(contributors)
        ng_xml.search('/ead/archdesc/did/origination/persname[@role="contributor"]').each(&:remove)

        origination = ng_xml.at('/ead/archdesc/did/origination')
        if origination.nil?
          did_node = ng_xml.at('/ead/archdesc/did')
          origination = Nokogiri::XML::Node.new('origination', ng_xml)
          did_node.add_child(origination)
        end
        contributors.each do |disp|
          next if disp.empty?

          node = Nokogiri::XML::Node.new('persname', ng_xml)
          node.content = disp
          node[:role] = 'contributor'
          origination.add_child(node)
        end
      end

      #
      # @param people [Hash] the attributes and content required to create a persname
      # @option :display [Array<String>] the content for the node
      # @option :role [Array<String>] the role attribute for the node
      # @option :tag [Array<String>] the name of the person tag to add
      def add_name_coverage(people)
        return unless people.is_a?(Hash)
        people.symbolize_keys!
        valid_keys = [:tag, :display, :role].all? { |s| people.key? s }
        return unless valid_keys && people[:display].size == people[:role].size && people[:role].size == people[:tag].size

        ng_xml.search('/ead/archdesc/controlaccess/*[(local-name()="name" or local-name()="persname" or local-name()="famname" or local-name()="corpname") and not(@role="subject")]').each(&:remove)

        control_a = ng_xml.at('/ead/archdesc/controlaccess')
        if control_a.nil?
          archdesc_node = ng_xml.at('/ead/archdesc')
          control_a = Nokogiri::XML::Node.new('controlaccess', ng_xml)
          archdesc_node.add_child(control_a)
        end
        people[:display].each_with_index do |disp, idx|
          next unless DRI::Vocabulary.ead_people_tags.include?(people[:tag][idx])
          next if disp.empty?

          node = Nokogiri::XML::Node.new(people[:tag][idx], ng_xml)
          node.content = disp
          node[:role] = people[:role][idx] unless people[:role][idx].empty?
          control_a.add_child(node)
        end
      end

      def add_temporal_coverage(dates)
        return unless dates.is_a?(Hash)
        dates.symbolize_keys!
        valid_keys = [:display, :normal, :datechar].all? { |s| dates.key? s }
        return unless valid_keys && dates[:display].size == dates[:normal].size && dates[:normal].size == dates[:datechar].size

        ng_xml.search('/ead/archdesc/did/unitdate[not(contains(@datechar, "creation"))]').each(&:remove)

        did_node = ng_xml.at('/ead/archdesc/did')

        dates[:display].each_with_index do |disp, idx|
          next if disp.empty?

          node = Nokogiri::XML::Node.new('unitdate', ng_xml)
          node.content = disp
          node[:datechar] = dates[:datechar][idx]
          node[:normal] = dates[:normal][idx] unless dates[:normal][idx].empty?
          did_node.add_child(node)
        end
      end

      def add_related_material(materials)
        links = materials.select{ |i| i[/\A#{URI.regexp(['http', 'https'])}\z/] }

        ng_xml.search('/ead/archdesc/relatedmaterial').each(&:remove)

        arch_desc = ng_xml.at('/ead/archdesc')
        # Add related materials that are not external links
        links.each do |link|
          next if  link.empty?

          node = Nokogiri::XML::Node.new('relatedmaterial', ng_xml)
          ext_ref = Nokogiri::XML::Node.new('extref', ng_xml)
          ext_ref['href'] = link
          node.add_child(ext_ref)
          arch_desc.add_child(node)
        end
      end

      def add_alternative_form(materials)
        links = materials.select{ |i| i[/\A#{URI.regexp(['http', 'https'])}\z/] }

        ng_xml.search('/ead/archdesc/altformavail').each(&:remove)

        arch_desc = ng_xml.at('/ead/archdesc')
        links.each do |link|
          next if link.empty?

          node = Nokogiri::XML::Node.new('altformavail', ng_xml)
          p = Nokogiri::XML::Node.new('p', ng_xml)
          ext_ref = Nokogiri::XML::Node.new('extref', ng_xml)
          ext_ref['href'] = link
          p.add_child(ext_ref)
          node.add_child(p)
          arch_desc.add_child(node)
        end
      end

      def add_geogname_coverage_access(locations)
        return unless locations.is_a?(Hash)
        locations.symbolize_keys!
        valid_keys = [:type, :display].all? { |s| locations.key? s }
        return unless valid_keys && locations[:type].size == locations[:display].size

        ng_xml.search('/ead/archdesc/controlaccess/geogname[not(@role="subject")]').each(&:remove)

        control_a = ng_xml.at('/ead/archdesc/controlaccess')
        if control_a.nil?
          archdesc_node = ng_xml.at('/ead/archdesc')
          control_a = Nokogiri::XML::Node.new('controlaccess', ng_xml)
          archdesc_node.add_child(control_a)
        end
        locations[:display].each_with_index do |loc, idx|
          next if loc.empty?

          node = Nokogiri::XML::Node.new('geogname', ng_xml)
          node.content = loc
          unless locations[:type][idx].empty?
            case locations[:type][idx]
            when 'dcterms:Point'
              node['rules'] = 'dcterms:Point'
            when 'dcterms:Box'
              node['rules'] = 'dcterms:Box'
            when 'logainm'
              node['source'] = 'logainm'
            end
          end
          control_a.add_child(node)
        end
      end

      def add_language(languages)
        return unless languages.is_a?(Hash)

        languages.symbolize_keys!
        valid_keys = [:langcode, :text].all? { |s| languages.key? s }

        return unless valid_keys && languages[:langcode].size == languages[:text].size

        ng_xml.search('/ead/archdesc/did/langmaterial/language').each(&:remove)

        lang_mat = ng_xml.at('/ead/archdesc/did/langmaterial')
        if lang_mat.nil?
          did_node = ng_xml.at('/ead/archdesc/did')
          lang_mat = Nokogiri::XML::Node.new('langmaterial', ng_xml)
          did_node.add_child(lang_mat)
        end
        languages[:text].each_with_index do |lang, idx|
          next if lang.empty?

          node = Nokogiri::XML::Node.new('language', ng_xml)
          node.content = lang
          node[:langcode] = languages[:langcode][idx] unless languages[:langcode][idx].empty?
          lang_mat.add_child(node)
        end
      end

      def retrieve_terms_hash
        terms_hash = {}
        terms_hash[:title] = title

        # Creator
        creator_hash = {}
        creator_hash[:display] = []
        creator_hash[:role] = []
        creator_hash[:tag] = []
        ng_xml.search('/ead/archdesc/did/origination/*[(local-name()="name" or local-name()="persname" or local-name()="famname" or local-name()="corpname") and not(@role="contributor")]').each do |node|
          creator_hash[:display] << node.content
          creator_hash[:role] << (node['role'].nil? ? '' : node['role'])
          creator_hash[:tag] << node.name
        end
        terms_hash[:creator] = creator_hash

        terms_hash[:contributor] = contributor
        terms_hash[:publisher] = publisher
        terms_hash[:desc_scope_content] = desc_scope_content
        terms_hash[:desc_abstract] = desc_abstract
        terms_hash[:desc_biog_hist] = desc_biog_hist
        terms_hash[:desc_scope_content] = desc_scope_content
        terms_hash[:rights] = rights
        terms_hash[:type] = type

        published_date_hash = {}
        published_date_hash[:display] = []
        published_date_hash[:normal] = []
        ng_xml.search('/ead/eadheader/filedesc/publicationstmt/date').each do |node|
          published_date_hash[:display] << node.content
          published_date_hash[:normal] << (node['normal'].nil? ? '' : node['normal'])
        end
        terms_hash[:published_date] = published_date_hash

        creation_date_hash = {}
        creation_date_hash[:display] = []
        creation_date_hash[:normal] = []
        ng_xml.search('/ead/archdesc/did/unitdate[@datechar[contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "creation")]]').each do |node|
          creation_date_hash[:display] << node.content
          creation_date_hash[:normal] << (node['normal'].nil? ? '' : node['normal'])
        end
        terms_hash[:creation_date] = creation_date_hash

        name_coverage_hash = {}
        name_coverage_hash[:display] = []
        name_coverage_hash[:role] = []
        name_coverage_hash[:tag] = []
        ng_xml.search('/ead/archdesc/controlaccess/*[(local-name()="name" or local-name()="persname" or local-name()="famname" or local-name()="corpname") and not(@role="subject")]').each do |node|
          name_coverage_hash[:display] << node.content
          name_coverage_hash[:role] << (node['role'].nil? ? '' : node['role'])
          name_coverage_hash[:tag] << node.name
        end
        terms_hash[:name_coverage] = name_coverage_hash

        geogname_coverage_access_hash = {}
        geogname_coverage_access_hash[:display] = []
        geogname_coverage_access_hash[:type] = []
        ng_xml.search('/ead/archdesc/controlaccess/geogname[not(@role="subject")]').each do |node|
          geogname_coverage_access_hash[:display] << node.content
          if !node['source'].nil?
            geogname_coverage_access_hash[:type] << node['source']
          else
            geogname_coverage_access_hash[:type] << (node['rules'].nil? ? '' : node['rules'])
          end
        end
        terms_hash[:geogname_coverage_access] = geogname_coverage_access_hash

        temporal_coverage_hash = {}
        temporal_coverage_hash[:display] = []
        temporal_coverage_hash[:normal] = []
        temporal_coverage_hash[:datechar] = []
        ng_xml.search('/ead/archdesc/did/unitdate[not(contains(@datechar, "creation"))]').each do |node|
          temporal_coverage_hash[:display] << node.content
          temporal_coverage_hash[:normal] << (node['normal'].nil? ? '' : node['normal'])
          temporal_coverage_hash[:datechar] << (node['datechar'].nil? ? '' : node['datechar'])
        end
        terms_hash[:temporal_coverage] = temporal_coverage_hash

        terms_hash[:subject] = subject
        terms_hash[:name_subject] = name_subject
        terms_hash[:persname_subject] = persname_subject
        terms_hash[:corpname_subject] = corpname_subject
        terms_hash[:famname_subject] = famname_subject
        terms_hash[:geogname_subject] = geogname_subject

        terms_hash[:related_material] = related_material
        terms_hash[:alternative_form] = alternative_form

        language_hash = {}
        language_hash[:text] = []
        language_hash[:langcode] = []
        language.each_with_index do |value, idx|
          language_hash[:text] << value
          language_hash[:langcode] << (language(idx).langcode_at.empty? ? '' : language(idx).langcode_at[0])
        end
        terms_hash[:language] = language_hash

        terms_hash
      end

      # No parent to update as Root collection
      def update_parent_metadata(_parent, _full_metadata)
      end

      def custom_validations
        errors = {}

        # Mandatory elements at collection-level
        # Mandatory elements at collection-level
        title_result = false
        creator_result = false
        description_result = false
        creation_date_result = false
        rights_result = false

        # EAD-specific validation from best practices
        ead_id_result = false
        cc_result = false
        rc_result = false
        ead_level_result = false
        ead_level_other_result = false

        # Title
        title.each { |curr_title| title_result = true unless curr_title.blank? }
        # Creator
        creator.each { |curr_creator| creator_result = true unless curr_creator.blank? }
        # Description
        description.each { |curr_description| description_result = true unless curr_description.blank? }
        # Creation date
        creation_date.each { |curr_cdate| creation_date_result = true unless curr_cdate.blank? }
        # Rights
        rights.each { |curr_r| rights_result = true unless curr_r.blank? }

        # EAD-specific
        if DRI::Vocabulary.ead_level_values.include?(ead_level.first)
          ead_level.each { |curr_ead_level| ead_level_result = true unless curr_ead_level.blank? }
          ead_level_other.each { |curr_ead_level| ead_level_other_result = true unless curr_ead_level.blank? }
        end

        # Identifier validation
        identifier.each { |curr_ead_id| ead_id_result = true unless curr_ead_id.blank? }
        # Validation for eadid, @countrycode is a mandatory attribute
        # for eadid element
        country_code.each { |curr_cc| cc_result = true unless curr_cc.blank? }
        # Validation for eadid, @mainagencycode (repository_code here)
        # is mandatory for eadid element
        repository_code.each { |curr_rc| rc_result = true unless curr_rc.blank? }

        # DRI Compulsory elements
        errors[:title] = "can\'t be blank" if title_result == false
        errors[:creator] = "can\'t be blank" if creator_result == false
        errors[:description] = "can\'t be blank" if description_result == false
        errors[:creation_date] = "can\'t be blank" if creation_date_result == false
        errors[:rights] = "can\'t be blank" if rights_result == false

        # Specific EAD validation
        if ead_level.include?('otherlevel')
          errors[:ead_level_other] = "can\'t be blank" if ead_level_other_result == false
        else
          errors[:ead_level] = "can\'t be blank" if ead_level_result == false
        end

        # EADID validation
        # 1. eadid must be present
        # 1.1 the attribute mainagencycode is compulsory for eadid
        # 1.2 the attribute countrycode is compulsory for eadid
        if ead_id_result == false
          errors[:identifier] = "can\'t be blank"
        elsif cc_result == false || rc_result == false
          errors[:identifier] = 'invalid use'
          errors[:country_code] = "can\'t be blank" if cc_result == false
          errors[:repository_code] = "can\'t be blank" if rc_result == false
        end

        errors
      end # custom_validations
    end # class
  end # module
end # module
