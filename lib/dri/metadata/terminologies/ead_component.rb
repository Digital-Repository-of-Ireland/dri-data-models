module DRI::Metadata::Terminologies
  module EadComponent

    # OM (Opinionated Metadata) terminology mapping to an EAD Components (Sub-collections or Objects)
    def load_inherited_terminology
      # OM (Opinionated Metadata) terminology mapping to an EAD Components (Sub-collections or Objects)
      set_terminology do |t|
        t.root(path: '*', namespace_prefix: nil)

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

        t.ext_ref_p(path: 'p') {
          t.ext_ref(ref: [:ext_ref])
        }

        # c, c01..c12
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

        t.biog_hist(path: 'bioghist') {
          t.p(ref: [:p])
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
          t.extent(path: 'extent')
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

        t.note {
          t.p(ref: [:p])
        }

        # We need to keep track of the unitid in order to sync this XML snippet to the correct
        # component tag in the complete EAD XML datastream in the collection object!
        t.unit_id(path: 'unitid') {
          t.repository_code_at(path: { attribute: 'repositorycode' })
          t.country_code_at(path: { attribute: 'countrycode' })
          t.identifier_at(path: { attribute: 'identifier' })
          t.url_at(path: { attribute: 'url' })
          t.public_id_at(path: { attribute: 'publicid' })
        }

        t.did {
          t.unit_id(ref: [:unit_id])
          t.unit_title(path: 'unittitle')
          t.unit_date(ref: [:unit_date])
          t.unitdate_creation(ref: [:unit_date], path: 'unitdate[@datechar[contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "creation")]]')
          t.unitdate_pub(ref: [:unit_date], attributes: { datechar: 'publication' })
          t.unit_date_other(ref: [:unit_date_other])
          t.origination(ref: [:origination])
          t.abstract
          t.lang_material(ref: [:lang_material])
          t.dao(ref: [:dao])
          t.phys_desc(ref: [:phys_desc])
          t.note(ref: [:note])
          t.repository
        }

        t.c(path: '*', namespace_prefix: nil) {
          # level attributes
          t.ead_level_at(path: { attribute: 'level' })
          t.other_level_at(path: { attribute: 'otherlevel' })

          t.did(ref: [:did])
          t.control_access(ref: [:control_access])
          t.biog_hist(ref: [:biog_hist])
          t.scope_content(ref: [:scope_content])
          t.use_restrict(ref: [:use_restrict])
          t.rel_mat(ref: [:rel_mat])
          t.alt_form(ref: [:alt_form])
          t.dao(ref: [:dao])
          t.dsc
        }

        # DRI mandatory fields 1-to-1 mappings
        t.title(proxy: [:c, :did, :unit_title], index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])
        t.language(proxy: [:c, :did, :lang_material, :lang], index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.language_facetable])
        t.contributor(proxy: [:c, :did, :origination, :person_contributor], index_as: [DRI::Metadata::Descriptors.cleaned_facetable, DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable, :sortable])
        t.publisher(proxy: [:c, :did, :repository], index_as: [DRI::Metadata::Descriptors.cleaned_searchable])
        t.rights(proxy: [:c, :use_restrict, :p], index_as: [DRI::Metadata::Descriptors.cleaned_displayable, :stored_searchable])
        t.resource_type(proxy: [:c, :did, :phys_desc, :genre_form], index_as: [DRI::Metadata::Descriptors.cleaned_facetable, DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])

        t.creation_date(proxy: [:c, :did, :unitdate_creation])
        t.published_date(proxy: [:c, :did, :unitdate_pub])
        t.subject(proxy: [:c, :control_access, :subject], index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_facetable, DRI::Metadata::Descriptors.cleaned_displayable])

        t.description(path: '/*/scopecontent/p | /*[not(scopecontent)]/did/abstract | /*[not(scopecontent) and not(did/abstract)]/bioghist/p', index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])
        t.desc_abstract(proxy: [:c, :did, :abstract])
        t.desc_biog_hist(proxy: [:c, :biog_hist, :p])
        t.desc_dao_desc(proxy: [:c, :did, :dao, :dao_desc, :p])
        t.desc_scope_content(proxy: [:c, :scope_content, :p])
        t.desc_note(proxy: [:c, :did, :note])

        t.creator(path: '/*/did/origination/text()[normalize-space()]  | /*/did/origination/*[(local-name()="name" or local-name()="persname" or local-name()="famname" or local-name()="corpname") and not(@role="contributor")]')
        t.creator_role(proxy: [:c, :did, :origination, :person_creator])
        t.creator_name(proxy: [:c, :did, :origination, :name])
        t.creator_persname(proxy: [:c, :did, :origination, :pers_name])
        t.creator_corpname(proxy: [:c, :did, :origination, :corp_name])
        t.creator_famname(proxy: [:c, :did, :origination, :fam_name])

        # Subjects (including names, persnames, corpnames and famnames with @role='subject', nested within <controlaccess>)
        t.name_subject(proxy: [:c, :control_access, :name], index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_facetable, DRI::Metadata::Descriptors.cleaned_displayable])
        t.persname_subject(proxy: [:c, :control_access, :pers_name], index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_facetable, DRI::Metadata::Descriptors.cleaned_displayable])
        t.corpname_subject(proxy: [:c, :control_access, :corp_name], index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_facetable, DRI::Metadata::Descriptors.cleaned_displayable])
        t.famname_subject(proxy: [:c, :control_access, :fam_name], index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_facetable, DRI::Metadata::Descriptors.cleaned_displayable])
        t.geogname_subject(proxy: [:c, :control_access, :geog_name], index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_facetable, DRI::Metadata::Descriptors.cleaned_displayable])

        # EAD level
        t.ead_level(proxy: [:c, :ead_level_at], index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])
        # Eadlevel - otherlevel
        t.ead_level_other(proxy: [:c, :other_level_at], index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])

        t.format(proxy: [:c, :did, :phys_desc, :extent], index_as: [DRI::Metadata::Descriptors.cleaned_facetable, DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])

        t.dao_did(proxy: [:c, :did, :dao])
        t.dao_other(proxy: [:c, :dao])
        # Dao
        t.dao_proxy(proxy: [:dao])
        # Dao_href
        t.dao_href_proxy(proxy: [:dao, :href_at])
        # Daodesc
        t.dao_desc_proxy(proxy: [:dao, :dao_desc, :p])

        # Identifier
        t.identifier(proxy: [:c, :did, :unit_id])
        # Compulsory attributes at finding aid level: identifier, repositorycode and countrycode, in <eadid>
        t.identifier_id(proxy: [:c, :did, :unit_id, :identifier_at])
        # Repositorycode
        t.repository_code(proxy: [:c, :did, :unit_id, :repository_code_at])
        # Countrycode
        t.country_code(proxy: [:c, :did, :unit_id, :country_code_at])
        t.identifier_url(proxy: [:c, :did, :unit_id, :url_at])
        t.identifier_public_id(proxy: [:c, :did, :unit_id, :public_id_at])

        # Related Material
        t.related_material(proxy: [:c, :rel_mat, :ext_ref, :href_at], index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])
        # Alternative Form Available
        t.alternative_form(proxy: [:c, :alt_form, :ext_ref_p, :ext_ref, :href_at], index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])

        # Mapping to geogname supporting DCMI Point and Box
        t.geocode_point(ref: :geog_name_cvg, attributes: { rules: 'dcterms:Point' })
        t.geocode_box(ref: :geog_name_cvg, attributes: { rules: 'dcterms:Box' })
        # Mapping to geogname supporting Logaimn URIs
        t.geocode_logainm(ref: :geog_name_cvg, attributes: { source: 'logainm' })

        # PROXIES FOR INDEXING
        # EAD coverage elements within control access headings, authority-controlled search across finding aids
        t.name_coverage(path: '/*/controlaccess/*[(local-name()="name" or local-name()="persname" or local-name()="famname" or local-name()="corpname") and not(@role="subject")]')
        t.persname_coverage(proxy: [:c, :control_access, :pers_name_cvg])
        t.corpname_coverage(proxy: [:c, :control_access, :corp_name_cvg])
        t.famname_coverage(proxy: [:c, :control_access, :fam_name_cvg])
        t.geographical_coverage(proxy: [:geog_name_cvg])
        t.geogname_coverage_access(proxy: [:c, :control_access, :geog_name_cvg])
        t.temporal_coverage(proxy: [:did, :unit_date_other])

        t.creation_date_idx(path: '/*/did/unitdate[@datechar[contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "creation")]]/@normal')
        t.published_date_idx(path: '/*/did/unitdate[@datechar="publication"]/@normal')
        t.temporal_coverage_idx(path: 'did/unitdate[@datechar[not(contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "creation")) and not(contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "publication"))]]/@normal')
        t.date_idx(proxy: [:date, :normal_at])
      end # set_terminology
    end
  end
end
