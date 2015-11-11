module DRI
  module Metadata
    # An ActiveFedora datastream that interacts with MODS.
    class Mods < DRI::Metadata::Base
      # MODS XML constants.
      MODS_NS_PREFIX = 'mods'
      MODS_NS = 'http://www.loc.gov/mods/v3'
      MODS_SCHEMA = 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-5.xsd'
      CR_NS_PREFIX = 'copyrightMD'
      CR_NS = 'http://www.cdlib.org/inside/diglib/copyrightMD'

      # Set OM (Opinionated Metadata) terminology
      set_terminology do |t|
        t.root(path: 'mods', namespace_prefix: MODS_NS_PREFIX, "xmlns:#{CR_NS_PREFIX}" => CR_NS, schema: MODS_SCHEMA)

        t.title_info(path: 'titleInfo', namespace_prefix: MODS_NS_PREFIX) {
          t.main_title(path: 'title', namespace_prefix: MODS_NS_PREFIX)
          t.subtitle(path: 'subTitle', namespace_prefix: MODS_NS_PREFIX)
        }

        # Map to the mods record identifier (absolute xpath here)
        t.identifier_record(path: 'identifier', namespace_prefix: MODS_NS_PREFIX)
        t.identifier_doi(ref: :identifier_record, attributes: { type: 'doi' }, namespace_prefix: MODS_NS_PREFIX)
        t.identifier_uri(ref: :identifier_record, attributes: { type: 'uri' }, namespace_prefix: MODS_NS_PREFIX)
        t.identifier_local(ref: :identifier_record, attributes: { type: 'local' }, namespace_prefix: MODS_NS_PREFIX)
        t.identifier_asset(ref: :identifier_record, attributes: { type: 'asset' }, namespace_prefix: MODS_NS_PREFIX)

        t.abstract(path: 'abstract', index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable],
                   namespace_prefix: MODS_NS_PREFIX)

        t.role_term(path: 'roleTerm', namespace_prefix: MODS_NS_PREFIX) {
          t.role_term_type_at(path: { attribute: 'type' })
        }

        t.marcrel_role_term(ref: :role_term,
                            attributes: { authority: 'marcrelator' },
                            namespace_prefix: MODS_NS_PREFIX)
        # Role
        t.role(path: 'role', namespace_prefix: MODS_NS_PREFIX) {
          t.role_text(ref: [:role_term], attributes: { type: 'text' }, namespace_prefix: MODS_NS_PREFIX)
          t.role_code(ref: [:role_term], attributes: { type: 'code' }, namespace_prefix: MODS_NS_PREFIX)
          t.marcrel_role_text(ref: [:marcrel_role_term], attributes: { type: 'text' }, namespace_prefix: MODS_NS_PREFIX)
          t.marcrel_role_code(ref: [:marcrel_role_term], attributes: { type: 'code' }, namespace_prefix: MODS_NS_PREFIX)
        }

        # This is a mods:name. The underscore is purely to avoid namespace conflicts.
        t.name(namespace_prefix: MODS_NS_PREFIX) {
          t.name_part(path: 'namePart', type: :string, namespace_prefix: MODS_NS_PREFIX)
          t.name_role(ref: [:role], namespace_prefix: MODS_NS_PREFIX)
          t.name_date(path: 'namePart', attributes: { type: 'date' }, namespace_prefix: MODS_NS_PREFIX)
          t.last_name(path: 'namePart', attributes: { type: 'family' }, namespace_prefix: MODS_NS_PREFIX)
          t.first_name(path: 'namePart', attributes: { type: 'given' }, namespace_prefix: MODS_NS_PREFIX)
        }

        # Language
        t.language_any(path: 'language', namespace_prefix: MODS_NS_PREFIX) {
          t.object_part_at(path: { attribute: 'objectPart' })
          t.language_text(path: 'languageTerm', attributes: { type: 'text' }, namespace_prefix: MODS_NS_PREFIX)
          t.language_code(path: 'languageTerm', attributes: { type: 'code' }, namespace_prefix: MODS_NS_PREFIX)
        }

        # TODO: revise the :ref language specific to resource
        t.language_any_object_part(ref: :language_any, namespace_prefix: MODS_NS_PREFIX)

        # Temporal
        t.temporal(path: 'temporal', namespace_prefix: MODS_NS_PREFIX) {
          t.temporal_key_at(path: { attribute: 'keyDate' })
          t.temporal_point(path: { attribute: 'point' })
          t.temporal_encoding_at(path: { attribute: 'encoding' })
        }
        t.temporal_single(ref: :temporal, attributes: { point: :none }, namespace_prefix: MODS_NS_PREFIX)

        # Geographic
        t.geographic(path: 'geographic', namespace_prefix: MODS_NS_PREFIX) {
          t.geographic_authority_at(path: { attribute: 'authority' })
          t.geographic_value_uri_at(path: { attribute: 'valueURI' })
          t.geographic_lang_at(path: { attribute: 'lang' })
        }
        t.geographic_logainm(ref: :geographic, attributes: { authority: 'logainm' }, namespace_prefix: MODS_NS_PREFIX)
        # HierarchicalGeographic
        t.hierarchical_geographic(path: 'hierarchicalGeographic', namespace_prefix: MODS_NS_PREFIX) {
          t.hierarchical_geographic_lang_at(path: { attribute: 'lang' })
        }
        # GeographicCode
        t.geographic_code(path: 'geographicCode', namespace_prefix: MODS_NS_PREFIX) {
          t.geographic_code_lang_at(path: { attribute: 'lang' })
        }
        # Cartographics
        t.cartographics(path: 'cartographics', namespace_prefix: MODS_NS_PREFIX) {
          t.coordinates(namespace_prefix: MODS_NS_PREFIX)
          t.scale(namespace_prefix: MODS_NS_PREFIX)
          t.projection(namespace_prefix: MODS_NS_PREFIX)
        }

        t.main_subject(path: 'subject', namespace_prefix: MODS_NS_PREFIX) {
          t.subject_authority_at(path: { attribute: 'authority' })
          t.subject_topic(path: 'topic', namespace_prefix: MODS_NS_PREFIX)
          t.subject_name(ref: [:name])
          # Temporal
          t.subject_temporal(ref: [:temporal], namespace_prefix: MODS_NS_PREFIX)
          t.subject_temporal_single(ref: [:temporal_single], namespace_prefix: MODS_NS_PREFIX)
          # Geographic
          t.subject_geographic(ref: [:geographic], namespace_prefix: MODS_NS_PREFIX)
          t.subject_geographic_logainm(ref: [:geographic_logainm], namespace_prefix: MODS_NS_PREFIX)
          # HierarchicalGeographic
          t.subject_hierarchical_geographic(ref: [:hierarchical_geographic], namespace_prefix: MODS_NS_PREFIX)
          # GeographicCode
          t.subject_geographic_code(ref: [:geographic_code], namespace_prefix: MODS_NS_PREFIX)
          # Cartographics
          t.subject_cartographics(ref: [:cartographics], namespace_prefix: MODS_NS_PREFIX)
        }

        t.place(path: 'place', namespace_prefix: MODS_NS_PREFIX) {
          t.place_term(path: 'placeTerm', namespace_prefix: MODS_NS_PREFIX) {
            t.place_type_at(path: { attribute: 'type' })
            t.place_authority_at(path: { attribute: 'authority' })
          }
        }

        t.date_created(path: 'dateCreated', namespace_prefix: MODS_NS_PREFIX) {
          t.encoding_at(path: { attribute: 'encoding' })
          t.point_at(path: { attribute: 'point' })
          t.key_date_at(path: { attribute: 'keyDate' })
        }
        t.date_created_start(ref: :date_created, namespace_prefix: MODS_NS_PREFIX, attributes: { point: 'start' })
        t.date_created_end(ref: :date_created, namespace_prefix: MODS_NS_PREFIX, attributes: { point: 'end' })

        t.date_issued(path: 'dateIssued', namespace_prefix: MODS_NS_PREFIX) {
          t.encoding_at(path: { attribute: 'encoding' })
          t.point_at(path: { attribute: 'point' })
          t.key_date_at(path: { attribute: 'keyDate' })
        }
        t.date_issued_start(ref: :date_issued, namespace_prefix: MODS_NS_PREFIX, attributes: { point: 'start' })
        t.date_issued_end(ref: :date_issued, namespace_prefix: MODS_NS_PREFIX, attributes: { point: 'end' })

        t.date_captured(path: 'dateCaptured', namespace_prefix: MODS_NS_PREFIX) {
          t.encoding_at(path: { attribute: 'encoding' })
          t.point_at(path: { attribute: 'point' })
          t.key_date_at(path: { attribute: 'keyDate' })
        }
        t.date_captured_start(ref: :date_captured, namespace_prefix: MODS_NS_PREFIX, attributes: { point: 'start' })
        t.date_captured_end(ref: :date_captured, namespace_prefix: MODS_NS_PREFIX, attributes: { point: 'end' })

        t.date_other(path: 'dateOther', namespace_prefix: MODS_NS_PREFIX) {
          t.encoding_at(path: { attribute: 'encoding' })
          t.point_at(path: { attribute: 'point' })
          t.key_date_at(path: { attribute: 'keyDate' })
        }
        t.date_other_start(ref: :date_other, namespace_prefix: MODS_NS_PREFIX, attributes: { point: 'start' })
        t.date_other_end(ref: :date_other, namespace_prefix: MODS_NS_PREFIX, attributes: { point: 'end' })

        t.origin_info(path: 'originInfo', namespace_prefix: MODS_NS_PREFIX) {
          t.o_date_created(ref: [:date_created], attributes: { point: :none }, namespace_prefix: MODS_NS_PREFIX)
          t.o_date_created_start(ref: [:date_created_start], namespace_prefix: MODS_NS_PREFIX)
          t.o_date_created_end(ref: [:date_created_end], namespace_prefix: MODS_NS_PREFIX)
          t.o_date_issued(ref: [:date_issued], attributes: { point: :none }, namespace_prefix: MODS_NS_PREFIX)
          t.o_date_issued_start(ref: [:date_issued_start], namespace_prefix: MODS_NS_PREFIX)
          t.o_date_issued_end(ref: [:date_issued_end], namespace_prefix: MODS_NS_PREFIX)
          # Uncategorised date if important to capture
          t.o_date_other(ref: [:date_other], attributes: { point: :none }, namespace_prefix: MODS_NS_PREFIX)
          t.o_date_other_start(ref: [:date_other_start], attributes: { point: :none }, namespace_prefix: MODS_NS_PREFIX)
          t.o_date_other_end(ref: [:date_other_end], attributes: { point: :none }, namespace_prefix: MODS_NS_PREFIX)
          t.copyright_date(path: 'copyrightDate', namespace_prefix: MODS_NS_PREFIX)
          t.publisher(namespace_prefix: MODS_NS_PREFIX)
          # Possible elements for source
          t.origin_place(ref: [:place], namespace_prefix: MODS_NS_PREFIX)
          # three dates below not recommended as technical metadata
          t.o_date_captured(ref: [:date_captured], attributes: { point: :none }, namespace_prefix: MODS_NS_PREFIX)
          t.o_date_captured_start(ref: [:date_captured_start], namespace_prefix: MODS_NS_PREFIX)
          t.o_date_captured_end(ref: [:date_captured_end], namespace_prefix: MODS_NS_PREFIX)
          t.date_valid(path: 'dateValid', namespace_prefix: MODS_NS_PREFIX)
          t.date_modified(path: 'dateModified', namespace_prefix: MODS_NS_PREFIX)
          t.edition(namespace_prefix: MODS_NS_PREFIX)
          t.issuance(namespace_prefix: MODS_NS_PREFIX)
          t.frequency(namespace_prefix: MODS_NS_PREFIX)
        }

        t.access_condition(path: 'accessCondition', namespace_prefix: MODS_NS_PREFIX) {
          # It uses http://www.cdlib.org/inside/diglib/copyrightMD
          t.copyright(path: 'copyright', namespace_prefix: CR_NS_PREFIX) {
            t.status_at(path: { attribute: 'copyright.status' })
            t.rights_holder(path: 'rights.holder', namespace_prefix: CR_NS_PREFIX)
            t.general_note(path: 'general.note', namespace_prefix: CR_NS_PREFIX)
          }
        }

        t.type_resource(path: 'typeOfResource', namespace_prefix: MODS_NS_PREFIX) {
          t.collection_at(path: { attribute: 'collection' })
        }

        t.type_resource_collection(ref: :type_resource,
                                   attributes: { collection: 'yes' },
                                   namespace_prefix: MODS_NS_PREFIX)

        t.genre(path: 'genre', namespace_prefix: MODS_NS_PREFIX)

        # Note
        t.note(path: 'note', namespace_prefix: MODS_NS_PREFIX) {
          t.label_at(path: { attribute: 'displayLabel' })
          t.type_at(path: { attribute: 'type' })
        }
        # Note no type attr
        t.note_no_type(ref: :note, attributes: { type: 'none' }, namespace_prefix: MODS_NS_PREFIX)

        t.physical_description(path: 'physicalDescription', namespace_prefix: MODS_NS_PREFIX) {
          t.form(namespace_prefix: MODS_NS_PREFIX)
          t.reformatting_quality(path: 'reformattingQuality', namespace_prefix: MODS_NS_PREFIX)
          t.internet_media(path: 'internetMediaType', namespace_prefix: MODS_NS_PREFIX)
          t.extent(namespace_prefix: MODS_NS_PREFIX)
          t.digital_origin(path: 'digitalOrigin', namespace_prefix: MODS_NS_PREFIX)
          t.phys_desc_note(ref: [:note])
        }

        # location
        t.location(path: 'location', namespace_prefix: MODS_NS_PREFIX) {
          t.location_title(path: 'title', namespace_prefix: MODS_NS_PREFIX)
          t.physical_location(path: 'physicalLocation', namespace_prefix: MODS_NS_PREFIX)
          t.shelf_locator(path: 'shelfLocator', namespace_prefix: MODS_NS_PREFIX)
          t.location_url(path: 'url', namespace_prefix: MODS_NS_PREFIX)
          t.holding_simple(path: 'holdingSimple', namespace_prefix: MODS_NS_PREFIX)
          t.holding_external(path: 'holdingExternal', namespace_prefix: MODS_NS_PREFIX)
        }

        # tableOfContents
        t.table_contents(path: 'tableOfContents', namespace_prefix: MODS_NS_PREFIX) {
          t.format_at(path: { attribute: 'altFormat' })
          t.content_at(path: { attribute: 'altContent' })
        }

        # classification
        t.classification(namespace_prefix: MODS_NS_PREFIX)

        # part
        t.part(path: 'part', namespace_prefix: MODS_NS_PREFIX) {
          t.detail(namespace_prefix: MODS_NS_PREFIX)
          t.extent(namespace_prefix: MODS_NS_PREFIX)
          t.date_part(path: 'date', namespace_prefix: MODS_NS_PREFIX)
          t.text(namespace_prefix: MODS_NS_PREFIX)
        }

        # recordInfo
        t.record_info(path: 'recordInfo', namespace_prefix: MODS_NS_PREFIX)

        t.lang_of_cataloging(path: 'languageOfCataloging', namespace_prefix: MODS_NS_PREFIX) {
          t.language_text(path: 'languageTerm', attributes: { type: 'text' }, namespace_prefix: MODS_NS_PREFIX)
          t.language_code(path: 'languageTerm', attributes: { type: 'code' }, namespace_prefix: MODS_NS_PREFIX)
          t.script_term_text(path: 'scriptTerm', attributes: { type: 'text' }, namespace_prefix: MODS_NS_PREFIX)
          t.script_term_code(path: 'scriptTerm', attributes: { type: 'code' }, namespace_prefix: MODS_NS_PREFIX)
        }

        t.target_audience(path: 'targetAudience', namespace_prefix: MODS_NS_PREFIX) {
          t.record_content_source(path: 'recordContentSource', namespace_prefix: MODS_NS_PREFIX)
          t.record_creation_date(path: 'recordCreationDate', namespace_prefix: MODS_NS_PREFIX)
          t.record_change_date(path: 'recordChangeDate', namespace_prefix: MODS_NS_PREFIX)
          t.record_identifier(path: 'recordIdentifier', namespace_prefix: MODS_NS_PREFIX)
          t.record_origin(path: 'recordOrigin', namespace_prefix: MODS_NS_PREFIX)
          t.lang_of_cataloging(ref: [:lang_of_cataloging])
          t.description_standard(path: 'descriptionStandard', namespace_prefix: MODS_NS_PREFIX)
        }

        # Related Item
        t.related_item(path: 'relatedItem', namespace_prefix: MODS_NS_PREFIX) {
          t.ri_id(ref: [:identifier_record], namespace_prefix: MODS_NS_PREFIX)
          t.ri_title_info(ref: [:title_info])
          t.ri_name(ref: [:name])
          t.ri_type(ref: [:type_resource])
          t.ri_genre(ref: [:genre])
          t.ri_origin_info(ref: [:origin_info])
          t.ri_language(ref: [:language_any])
          t.ri_physical_description(ref: [:physical_description])
          t.ri_abstract(ref: [:abstract])
          t.ri_table_contents(ref: [:table_contents])
          t.ri_target_audience(ref: [:target_audience])
          t.ri_note(ref: [:note])
          t.ri_subject(ref: [:main_subject])
          t.ri_classification(ref: [:classification])
          t.ri_location(ref: [:location])
          t.ri_access_condition(ref: [:access_condition])
          t.ri_part(ref: [:part])
          t.ri_extension(namespace_prefix: MODS_NS_PREFIX)
          t.ri_record_info(ref: [:record_info])
        }
        t.related_item_original(ref: :related_item, attributes: { type: 'original' }, namespace_prefix: MODS_NS_PREFIX)

        # ----------------------------------------------------------------------------------------------------------
        # Term proxies definition: must be absolute paths, avoid picking relatedItem elements
        # Record Identifier
        t.identifier(proxy: [:mods, :identifier_record])
        # Title
        t.title(proxy: [:mods, :title_info, :main_title],
                index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        # Creator
        t.creator(path: 'mods/mods:name[mods:role/mods:roleTerm/@authority="marcrelator" and mods:role/mods:roleTerm/@type="code" and (mods:role/mods:roleTerm[@type="code" and @authority="marcrelator"] = "cre")]/mods:namePart',
                  index_as: [Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable, :sortable],
                  namespace_prefix: MODS_NS_PREFIX)
        # Contributor
        t.contributor(path: 'mods/mods:name[mods:role/mods:roleTerm/@authority="marcrelator" and (mods:role/mods:roleTerm = "ctb")]/mods:namePart',
                      index_as: [Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable, :sortable],
                      namespace_prefix: MODS_NS_PREFIX)

        # Description: abstract, tableOfContents, or note
        t.description(path: '//mods:mods/mods:abstract | //mods:mods[not(mods:abstract)]/mods:note | //mods:mods[not(mods:abstract) and not(mods:note)]/mods:tableOfContents | //mods:mods[not(mods:abstract) and not(mods:note) and not(mods:tableOfContents)]/mods:physicalDescription/mods:note',
                      index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.desc_abstract(proxy: [:mods, :abstract], index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.desc_note(proxy: [:mods, :note], index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.desc_toc(proxy: [:mods, :table_contents], index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.desc_physdesc_note(proxy: [:mods, :physical_description, :phys_desc_note], index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])

        # Subject: defaults to subject/topic
        t.subject(proxy: [:mods, :main_subject, :subject_topic],
                  index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable])

        # language
        t.language(proxy: [:mods, :language_any, :language_code],
                   index_as: [Descriptors.cleaned_searchable, Descriptors.language_facetable])
        t.mods_language_text(proxy: [:mods, :language_any, :language_text])

        # Source
        t.source(path: 'mods/mods:relatedItem[@type="original"]/mods:location/mods:physicalLocation | mods/mods:relatedItem[@type="original" and not(mods:location)]/mods:titleInfo/mods:title',
                 index_as: [Descriptors.cleaned_displayable, Descriptors.cleaned_facetable],
                 namespace_prefix: MODS_NS_PREFIX)
        t.source_location(proxy: [:mods, :related_item_original, :ri_location, :location_title])
        t.source_physical_location(proxy: [:mods, :related_item_original, :ri_location, :physical_location])

        # Type
        t.type(proxy: [:mods, :type_resource],
               index_as: [Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.mods_type_collection(proxy: [:mods, :type_resource_collection])
        t.mods_genre(proxy: [:mods, :genre])

        # Rights - the type attribute with value 'use and reproduction' is DRI compulsory
        t.rights(proxy: [:mods, :access_condition],
                 index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.copyrightmd_rights(proxy: [:mods, :access_condition, :copyright, :rights_holder],
                             index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])

        # Publisher
        t.publisher(proxy: [:mods, :origin_info, :publisher],
                    index_as: [Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])

        # Published_date
        t.published_date(proxy: [:mods, :origin_info, :o_date_issued])
        # Issued (Published) date ranges
        t.issued_date_start(proxy: [:mods, :origin_info, :o_date_issued_start])
        t.issued_date_end(proxy: [:mods, :origin_info, :o_date_issued_end])

        # Creation_date
        t.creation_date(proxy: [:mods, :origin_info, :o_date_created])
        # Creation date ranges
        t.creation_date_start(proxy: [:mods, :origin_info, :o_date_created_start])
        t.creation_date_end(proxy: [:mods, :origin_info, :o_date_created_end])

        # Coverage
        # Subject name
        t.name_coverage(proxy: [:mods, :main_subject, :subject_name, :name_part], namespace_prefix: MODS_NS_PREFIX)

        # temporal_coverage
        t.temporal_coverage(proxy: [:mods, :main_subject, :subject_temporal_single])

        # geographical_coverage
        t.geographical_coverage(proxy: [:mods, :main_subject, :subject_geographic],
                                index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable],
                                namespace_prefix: MODS_NS_PREFIX)

        t.mods_geographic_code(proxy: [:mods, :main_subject, :subject_geographic_code], namespace_prefix: MODS_NS_PREFIX)

        # Roles proxy, similar to QDC
        DRI::Vocabulary.marc_relators.each do |role|
          if DRI::Vocabulary.marc_relators_index? role
            t.send "role_#{role}",
                 path: "mods/mods:name[mods:role/mods:roleTerm/@authority='marcrelator' and mods:role/mods:roleTerm/@type='code' and mods:role/mods:roleTerm = \"#{role}\"]/mods:namePart[not(@type=\"date\")]",
                 index_as: [Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable],
                 namespace_prefix: MODS_NS_PREFIX
          else
            t.send "role_#{role}",
                   path: "mods/mods:name[mods:role/mods:roleTerm/@authority='marcrelator' and mods:role/mods:roleTerm/@type='code' and mods:role/mods:roleTerm = \"#{role}\"]/mods:namePart[not(@type=\"date\")]",
                   namespace_prefix: MODS_NS_PREFIX
          end
        end

        # MODS Terms
        t.mods_id_local(proxy: [:mods, :identifier_local],
                        index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable],
                        namespace_prefix: MODS_NS_PREFIX)
        # id_asset - Used for sorting sequenced items
        t.id_asset(proxy: [:mods, :identifier_asset], index_as: [:stored_sortable], namespace_prefix: MODS_NS_PREFIX)

        t.mods_subtitle(proxy: [:mods, :title_info, :subtitle], namespace_prefix: MODS_NS_PREFIX)

        t.toc(ref: :table_contents, namespace_prefix: MODS_NS_PREFIX)

        # Other mappings to geographical/temporal
        t.mods_hierarchical_geographic(proxy: [:mods, :main_subject, :subject_hierarchical_geographic],
                                       namespace_prefix: MODS_NS_PREFIX)
        t.mods_cartographics_scale(proxy: [:mods, :main_subject, :subject_cartographics, :scale],
                                   namespace_prefix: MODS_NS_PREFIX)
        t.mods_cartographics_coordinates(proxy: [:mods, :main_subject, :subject_cartographics, :coordinates],
                                         namespace_prefix: MODS_NS_PREFIX)
        t.mods_cartographics_projection(proxy: [:mods, :main_subject, :subject_cartographics, :projection],
                                        namespace_prefix: MODS_NS_PREFIX)

        # language, specific to a terms of the MODS record: e.g. language for abstract
        t.language_object_part(ref: [:language_any_object_part])

        # Add TERMS for External relationships
        t.related_items_digital(proxy: [:mods, :location, :location_url])

        # Internal Relationships
        DRI::Vocabulary.mods_relationship_types.each do |rel|
          t.send "related_items_ids_#{rel}",
                 path: "relatedItem[@type='#{rel}']/mods:identifier[@type='local']",
                 namespace_prefix: MODS_NS_PREFIX
        end

        # External Relationships
        DRI::Vocabulary.mods_relationship_types.each do |rel|
          t.send "ext_related_items_ids_#{rel}",
                 path: "relatedItem[@type='#{rel}']/mods:location/mods:url", namespace_prefix: MODS_NS_PREFIX
        end

        # Proxies definition for TEMPORAL elements

        # Subject: temporal, date range (@point attribute)
        t.subject_date_start(path: 'subject/mods:temporal[@encoding="w3cdtf" or @encoding="iso8601"]',
                             attributes: { point: 'start' },
                             namespace_prefix: MODS_NS_PREFIX)
        t.subject_date_end(path: 'subject/mods:temporal[@encoding="w3cdtf" or @encoding="iso8601"]',
                           attributes: { point: 'end' },
                           namespace_prefix: MODS_NS_PREFIX)

        t.date(path: 'name/mods:namePart',
               attributes: { type: 'date' },
               namespace_prefix: MODS_NS_PREFIX)

        t.captured_date(proxy: [:mods, :origin_info, :o_date_captured])
        t.captured_date_start(proxy: [:mods, :origin_info, :o_date_captured_start])
        t.captured_date_end(proxy: [:mods, :origin_info, :o_date_captured_end])

        t.other_date(proxy: [:mods, :origin_info, :o_date_other])
        t.other_date_start(proxy: [:mods, :origin_info, :o_date_other_start])
        t.other_date_end(proxy: [:mods, :origin_info, :o_date_other_end])

        t.part_date(path: 'part/mods:date',
                    attributes: { point: :none },
                    namespace_prefix: MODS_NS_PREFIX)
        t.part_date_start(path: 'part/mods:date[@encoding="w3cdtf" or @encoding="iso8601"]',
                          attributes: { point: 'start' },
                          namespace_prefix: MODS_NS_PREFIX)
        t.part_date_end(path: 'part/mods:date[@encoding="w3cdtf" or @encoding="iso8601"]',
                        attributes: { point: 'end' },
                        namespace_prefix: MODS_NS_PREFIX)

        t.geocode_logainm(proxy: [:mods, :main_subject, :subject_geographic_logainm, :geographic_value_uri_at])

        t.origin_metadata(proxy: [:mods, :origin_info])
        t.subject_metadata(proxy: [:mods, :main_subject])
      end # set_terminology

      # Collection if typeOfResource[@collection="yes"]
      def collection?
        mods_type_collection.present? ? true : false
      end

      def roles=(roles)
        return unless roles.is_a?(Hash) &&
                      roles.key?('type') &&
                      roles.key?('name') &&
                      roles.key?('authority') &&
                      roles['type'].size == roles['name'].size &&
                      roles['name'].size == roles['authority'].size

        changed_roles = {}
        roles['type'].uniq.each { |role| changed_roles[role.sub(/^role_/, '')] = [] }

        roles['type'].each_with_index do |role, i|
          next if roles['name'][i].empty?

          role_name = role.sub(/^role_/, '')
          # roles['cre'] = [value, authority]
          changed_roles[role_name].push([roles['name'][i], roles['authority'][i]])
        end

        changed_roles.keys.each { |role| add_role(role, changed_roles[role]) }
      end

      # @param [String] code marc_relator code string
      # @param [Array] value array [value, authority]
      #
      def add_role(code, value)
        return if !DRI::Vocabulary.marc_relators.include?(code)
        xpath = "/mods:mods/mods:name[mods:role/mods:roleTerm[@type=\"code\"]=\"#{code}\"]"
        ng_xml.search(xpath, { 'xmlns:mods' => MODS_NS }).each(&:remove)

        record = ng_xml.root
        value.each do |elem|
          next if elem.empty? || elem.size != 2 || elem.first.blank?

          name_node = name_template(elem.first, code,
                                    DRI::Vocabulary.marc_relators_display[code],
                                    elem.last)

          record.add_child(name_node)
        end
      end

      # Build the xml doc
      def self.xml_template
        builder = Nokogiri::XML::Builder.new do |xml|
          xml[MODS_NS_PREFIX].mods(version: '3.5',
                                   'xmlns:xlink' => 'http://www.w3.org/1999/xlink',
                                   'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                                   'xmlns:mods' => MODS_NS,
                                   'xmlns:marcrel' => 'http://www.loc.gov/marc.relators/',
                                   'xmlns:dcterms' => 'http://purl.org/dc/terms/',
                                   "xmlns:#{CR_NS_PREFIX}" => CR_NS,
                                   'xsi:schemaLocation' => MODS_SCHEMA) {
            xml.titleInfo {
              xml.title # title
            }
            # Creator
            xml.name {
              xml.namePart
              xml.role {
                xml.roleTerm('cre', type: 'code', authority: 'marcrelator')
                xml.roleTerm(DRI::Vocabulary.marc_relators_creator['cre'], type: 'text', authority: 'marcrelator')
              }
            }
            # Creation date
            xml.originInfo {
              xml.dateCreated(encoding: 'iso8601') # creation_date
            }
            xml.abstract # description
            xml.subject(authority: '') {
              xml.topic # subject
            }
            xml.accessCondition(type: 'use and reproduction')
            xml.typeOfResource
          }
        end

        builder.doc
      end

      # Overriden. Solr indexing of custom fields
      # @param[Hash] solr_doc the Solr document to be merged
      # @param[Hash] opts
      #
      def to_solr(solr_doc = {}, opts = {})
        solr_doc = super(solr_doc, opts)

        # Title_sorted - A SOLR index for sorting titles
        if title.length > 0
          sorted_title = DRI::Metadata::Transformations.transform_title_for_sort(title[0])

          unless sorted_title.empty?
            solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('title_sorted', :stored_sortable, type: :string) => [sorted_title])
          end
        end

        # Type
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('type', :stored_searchable) => type_for_index)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('type', :facetable) => type_for_index)
        if collection?
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('type', :stored_searchable, type: :string) => 'Collection')
        end

        # MODS has several "name" tags, so we merge them together into the SOLR document
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

        # Subject
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('subject', :stored_searchable) => subject) unless subject == []
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('subject', :facetable) => subject) unless subject == []

        subject_place_array = subject_place_for_index
        subject_temporal_array = subject_temporal_for_index

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('name_coverage', :stored_searchable) => subject_name_for_index) unless name_coverage.empty?
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('name_coverage', :facetable) => subject_name_for_index) unless name_coverage.empty?

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('geographical_coverage', :stored_searchable) => subject_place_array) unless subject_place_array.empty?
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('geographical_coverage', :facetable) => subject_place_array) unless subject_place_array.empty?

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('temporal_coverage', :stored_searchable) => subject_temporal_array) unless subject_temporal_array.empty?
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('temporal_coverage', :facetable) => subject_temporal_array) unless subject_temporal_array.empty?

        # Indices for external relationships (to be displayed as URL)
        external_rels = *(DRI::Vocabulary.mods_relationship_types.map { |s| s.prepend('ext_related_items_ids_').to_sym })

        external_rels.each do |elem|
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name(elem, :stored_searchable) => send(elem)) unless send(elem) == []
        end

        # Index creation_date
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('creation_date', :stored_searchable) => creation_date_for_index)

        # Index Published Date
        unless published_date.empty? && issued_date_start.empty?
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('published_date', :stored_searchable) => display_single_date_for_index(published_date) |
                              display_date_range_for_index(issued_date_start, issued_date_end))
        end

        # Index date ranges
        date_ranges = date_ranges_for_index # ALL the date ranges
        # Creation date dateRange index
        cdate_ranges = date_ranges.select { |key, _value| ['creation_date', 'captured_date'].include?(key) }
        cdate_index = DRI::Metadata::Transformations.transform_date_ranges(cdate_ranges)
        solr_doc.merge!(Transformations::CREATION_DATE_RANGE_SOLR_FIELD => cdate_index) unless cdate_index.empty?

        # Published date dateRange index
        pdate_ranges = date_ranges.select { |key, _value| ['issued_date'].include?(key) }
        pdate_index = DRI::Metadata::Transformations.transform_date_ranges(pdate_ranges)
        solr_doc.merge!(Transformations::PUBLISHED_DATE_RANGE_SOLR_FIELD => pdate_index) unless pdate_index.empty?

        # Subject date dateRange index
        sdate_ranges = date_ranges.select { |key, _value| ['subject_date', 'date_other', 'part_date'].include?(key) }
        sdate_index = DRI::Metadata::Transformations.transform_date_ranges(sdate_ranges)
        solr_doc.merge!(Transformations::SUBJECT_DATE_RANGE_SOLR_FIELD => sdate_index) unless sdate_index.empty?

        # Geospatial indexing
        # Index logainm URIs in the appropriate geographic indices
        geospatial_hash = { coords: [], name: [], json: [] }

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
      end

      # Indexing Methods
      # --------------------------------------------------------------------------------------------------------------

      def creation_date_for_index
        unless creation_date.empty? && creation_date_start.empty?
          return display_single_date_for_index(creation_date) |
            display_date_range_for_index(creation_date_start, creation_date_end)
        end
        # 3 possible fields for this date
        #unless published_date.empty? && issued_date_start.empty?
        #  return display_single_date_for_index(published_date) |
        #    display_date_range_for_index(issued_date_start, issued_date_end)
        #end

        #unless captured_date.empty? && captured_date_start.empty?
        #  return display_single_date_for_index(captured_date) |
        #     display_date_range_for_index(captured_date_start, captured_date_end)
        #end

        []
      end

      def person_array_for_index
        creator | contributor | name_coverage
      end

      def subject_name_for_index
        names_array = []
        query = '/mods:mods/mods:subject/mods:name'
        ng_xml.search(query, { 'xml:mods' => MODS_NS }).each do |n|
          name_text = n.at('./mods:namePart')
          next if name_text.nil?

          role_text = n.at('./mods:role/mods:roleTerm[@type="text"]')
          names_array << (role_text.nil? ? name_text.content : "#{name_text.content} (#{role_text.content})")
        end

        names_array
      end

      # These are DRI Subject(Place)
      def subject_place_for_index
        geographical_coverage | mods_hierarchical_geographic | mods_cartographics_scale |
          mods_cartographics_coordinates | mods_cartographics_projection | mods_geographic_code | geocode_logainm
      end

      # These are DRI Subject(Place)
      def subject_temporal_for_index
        display_single_date_for_index(temporal_coverage) |
          display_single_date_for_index(other_date) |
          display_single_date_for_index(part_date) |
          display_date_range_for_index(subject_date_start, subject_date_end) |
          display_date_range_for_index(other_date_start, other_date_end) |
          display_date_range_for_index(part_date_start, part_date_end)
      end

      # No date ranges here, single date display (just the year)
      def display_single_date_for_index(date_field = [])
        date_field.collect do |value|
          begin
            display_date = ISO8601::DateTime.new(value).strftime('%b %d, %Y')
            DRI::Metadata::Transformations.create_dcmi_period(display_date, value)
          rescue ISO8601::Errors::StandardError
            # DCMI Period 'name' is the md value
            DRI::Metadata::Transformations.create_dcmi_period(value)
          end
        end
      end

      # Display of date ranges: start_year - end_year
      def display_date_range_for_index(date_start = [], date_end = [])
        date_range_display = date_start.collect.with_index do |name, idx|
          begin
            d_start = ISO8601::DateTime.new(name).strftime('%b %d, %Y')

            if date_start.size == date_end.size
              d_end = ISO8601::DateTime.new(date_end[idx]).strftime('%b %d, %Y')
              DRI::Metadata::Transformations.create_dcmi_period(d_start << ' - ' << d_end, name, date_end[idx])
            else
              Transformations.create_dcmi_period(d_start, name)
            end
          rescue ISO8601::Errors::StandardError
            DRI::Metadata::Transformations.create_dcmi_period(name) # DCMI Period 'name' is the md value
          end
        end

        date_range_display
      end

      # Return all date ranges formatted in the right format for indexing and single dates
      # Format: start_date/end_date (ISO8601)
      # @return Hash with all the dates present in the metadata to be indexed as date ranges
      def date_ranges_for_index
        dates_hash = {}

        creation_date_array = creation_date_start.map.with_index { |name, idx| creation_date_start.size == creation_date_end.size ? ("#{name}/#{creation_date_end[idx]}") : name }
        captured_date_array = captured_date_start.map.with_index { |name, idx| captured_date_start.size == captured_date_end.size ? ("#{name}/#{captured_date_end[idx]}") : name }
        issued_date_array = issued_date_start.map.with_index { |name, idx| issued_date_start.size == issued_date_end.size ? ("#{name}/#{issued_date_end[idx]}") : name }
        subject_date_array = subject_date_start.map.with_index { |name, idx| subject_date_start.size == subject_date_end.size ? ("#{name}/#{subject_date_end[idx]}") : name }
        date_other_array = other_date_start.map.with_index { |name, idx| other_date_start.size == other_date_end.size ? ("#{name}/#{other_date_end[idx]}") : name }
        part_date_array = part_date_start.map.with_index { |name, idx| part_date_start.size == part_date_end.size ? ("#{name}/#{part_date_end[idx]}") : name }

        dates_hash['creation_date'] = creation_date_array | creation_date
        dates_hash['captured_date'] = captured_date_array | captured_date
        dates_hash['issued_date'] = issued_date_array | published_date
        dates_hash['subject_date'] = subject_date_array | temporal_coverage
        dates_hash['date_other'] = date_other_array | other_date
        dates_hash['part_date'] = part_date_array | part_date

        dates_hash.delete_if { |_k, v| v.empty? }
      end

      def type_for_index
        # mods:typeOfResource last
        return mods_genre.map(&:capitalize) | type.map(&:capitalize) if mods_type_collection.present? || !type.present?

        type.map(&:capitalize)
      end

      # Methods for attribute updates

      def add_creator(creators)
        return unless creators.is_a? Hash

        valid_keys = [:display, :role, :authority].all? { |s| creators.key? s }
        return unless valid_keys && creators[:display].size == creators[:role].size && creators[:role].size == creators[:authority].size

        marc_creator_keys = DRI::Vocabulary.marc_relators_creator.keys

        marc_creator_keys.each do |key|
          xpath = "/mods:mods/mods:name[mods:role/mods:roleTerm[@type='code' and @authority='marcrelator' and text()='#{key}']]"
          ng_xml.search(xpath, { 'xmlns:mods' => MODS_NS }).each(&:remove)
        end

        record = ng_xml.root

        creators[:display].each_with_index do |elem, idx|
          next if elem.empty? || !marc_creator_keys.include?(creators[:role][idx])

          name = name_template(elem,
                               creators[:role][idx],
                               DRI::Vocabulary.marc_relators_creator[creators[:role][idx]],
                               creators[:authority][idx])
          record.add_child(name)
        end
      end

      def add_contributor(contributors)
        return unless contributors.is_a? Hash

        valid_keys = [:display, :role, :authority].all? { |s| contributors.key? s }
        return unless valid_keys && contributors[:display].size == contributors[:role].size && contributors[:role].size == contributors[:authority].size

        marc_ctb_keys = DRI::Vocabulary.marc_relators_contributor.keys

        marc_ctb_keys.each do |key|
          xpath = "/mods:mods/mods:name[mods:role/mods:roleTerm[@type='code' and @authority='marcrelator' and text()='#{key}']]"
          ng_xml.search(xpath, { 'xmlns:mods' => MODS_NS }).each(&:remove)
        end

        record = ng_xml.root

        contributors[:display].each_with_index do |elem, idx|
          next if elem.empty? || !marc_ctb_keys.include?(contributors[:role][idx])

          name = name_template(elem,
                               contributors[:role][idx],
                               DRI::Vocabulary.marc_relators_contributor[contributors[:role][idx]],
                               contributors[:authority][idx])
          record.add_child(name)
        end
      end

      def add_origin_metadata(origin)
        return unless origin.is_a? Array

        xpath = '/mods:mods/mods:originInfo'
        ng_xml.search(xpath, { 'xmlns:mods' => MODS_NS }).each(&:remove)

        record = ng_xml.root
        origin.each do |origin_elem|
          origin_node = Nokogiri::XML::Node.new('mods:originInfo', ng_xml)

          origin_elem.each do |_key, elem|
            tag = elem[:tag]
            next if tag.nil? || tag.empty? || !DRI::Vocabulary.mods_origin_info_tags.include?(tag)
            case tag
            when 'place'
              if elem[:content].present?
                node = Nokogiri::XML::Node.new('mods:place', ng_xml)
                p_term = Nokogiri::XML::Node.new('mods:placeTerm', ng_xml)
                p_term.content = elem[:content]
                node.add_child(p_term)
                origin_node.add_child(node)
              end
            when 'issuance', 'publisher', 'edition', 'frequency'
              if elem[:content].present?
                node = Nokogiri::XML::Node.new("#{MODS_NS_PREFIX}:#{tag}", ng_xml)
                node.content = elem[:content]
                origin_node.add_child(node)
              end
            else
              # date
              dates_array = date_template(tag, elem[:encoding], elem[:start], elem[:end])
              next if dates_array.nil?
              origin_node.add_child(dates_array.first)
              origin_node.add_child(dates_array.last) if dates_array.size > 1
            end
          end # elems from each origin info node

          record.add_child(origin_node) unless origin_node.children.empty?
        end # iterate over all origin info nodes
      end

      # add_origin_metadata

      def add_rights(statement)
        return unless statement.is_a? Hash

        valid_keys = [:status, :rights, :note].all? { |s| statement.key? s }
        return unless valid_keys && statement[:status].size == statement[:rights].size && statement[:rights].size == statement[:note].size

        xpath = '/mods:mods/mods:accessCondition'
        ng_xml.search(xpath, { 'xmlns:mods' => MODS_NS }).each(&:remove)

        record = ng_xml.root

        statement[:rights].each_with_index do |elem, idx|
          next if elem.empty?

          rnode = rights_template(elem, statement[:note][idx], statement[:status][idx])
          record.add_child(rnode)
        end
      end

      # add_rights

      # Subjects is an array of Hashes
      # [{ values: [{tag: '', content: ''}], authority: '' }, {...}]
      # where :values is an Array of Hashes, depending on the tag
      # 'topic'
      #
      def add_subject(subjects)
        return unless subjects.is_a? Array

        valid_hash = subjects.all? { |subj| [:values, :authority].all? { |s| subj.key? s } }
        return unless valid_hash

        xpath = '/mods:mods/mods:subject'
        ng_xml.search(xpath, { 'xmlns:mods' => MODS_NS }).each(&:remove)

        record = ng_xml.root

        subjects.each do |subj|
          next if subj[:values].empty?

          subject_node = Nokogiri::XML::Node.new('mods:subject', ng_xml)
          subject_node['authority'] = subj[:authority] unless subj[:authority].empty?

          subj[:values].each do |node|
            next unless node.key? :tag

            case node[:tag]
            when 'topic'
              next unless node.key? :content
              n = Nokogiri::XML::Node.new('mods:topic', ng_xml)
              n.content = node[:content]
            when 'name'
              next unless [:display, :role].all? { |s| node.key? s }
              n = name_template(node[:display],
                                node[:role],
                                DRI::Vocabulary.marc_relators_display[node[:role]],
                                node[:authority])
            when 'temporal'
              next unless [:start, :end, :encoding].all? { |s| node.key? s }
              dates_array = date_template('temporal', node[:encoding],
                                          node[:start], node[:end])
              next if dates_array.nil?
              subject_node.add_child(dates_array.first)
              subject_node.add_child(dates_array.last) if dates_array.size > 1
            when 'geographic'
              next unless node.key? :content
              n = Nokogiri::XML::Node.new('mods:geographic', ng_xml)
              if node.key?(:uri) && node[:uri].present?
                n['authority'] = 'logainm'
                n['valueURI'] = node[:uri]
              end
              n.content = node[:content]
            else
              next
            end
            subject_node.add_child(n) unless n.nil? || n.content.empty?
          end # iterate over subjects

          record.add_child(subject_node) unless subject_node.children.empty?
        end
      end

      # add_subject

      def add_type(types)
        return unless types.is_a? Hash

        valid_keys = [:collection, :content].all? { |s| types.key? s }
        return unless valid_keys

        xpath = '/mods:mods/mods:typeOfResource'
        ng_xml.search(xpath, { 'xmlns:mods' => MODS_NS }).each(&:remove)

        record = ng_xml.root

        collection_set = false
        types[:content].each do |elem|
          next if elem.empty? || !DRI::Vocabulary.mods_type_resource_values.include?(elem)

          type_node = Nokogiri::XML::Node.new('mods:typeOfResource', ng_xml)
          unless collection_set
            type_node['collection'] = 'yes' if types[:collection]
            collection_set = true
          end
          type_node.content = elem
          record.add_child(type_node)
        end
      end

      def add_mods_genre(genres)
        return unless genres.is_a? Hash

        valid_keys = [:content, :authority].all? { |s| genres.key? s }
        return unless valid_keys

        xpath = '/mods:mods/mods:genre'
        ng_xml.search(xpath, { 'xmlns:mods' => MODS_NS }).each(&:remove)

        record = ng_xml.root

        genres[:content].each_with_index do |elem, idx|
          next if elem.empty?

          genre_node = Nokogiri::XML::Node.new('mods:genre', ng_xml)
          genre_node.content = elem
          genre_node['authority'] = genres[:authority][idx] unless genres[:authority][idx].empty?
          record.add_child(genre_node)
        end
      end

      def add_language(languages)
        xpath = '/mods:mods/mods:language'
        ng_xml.search(xpath, { 'xmlns:mods' => MODS_NS }).each(&:remove)

        record = ng_xml.root

        languages.each do |lang|
          lang_node = Nokogiri::XML::Node.new('mods:language', ng_xml)
          lang_code = Nokogiri::XML::Node.new('mods:languageTerm', ng_xml)
          lang_code['type'] = 'code'
          lang_code.content = DRI::Metadata::Descriptors.standardise_language_code(lang)
          lang_text = Nokogiri::XML::Node.new('mods:languageTerm', ng_xml)
          lang_text['type'] = 'text'
          lang_text.content = lang

          lang_node.add_child(lang_code)
          lang_node.add_child(lang_text)
          record.add_child(lang_node)
        end
      end

      def name_template(content, code, text, authority = nil)
        name = Nokogiri::XML::Node.new('mods:name', ng_xml)
        name['authority'] = authority unless authority.nil? || authority.empty?
        name_part = Nokogiri::XML::Node.new('mods:namePart', ng_xml)
        name_part.content = content

        unless DRI::Vocabulary.marc_relators_display.key?(code)
          name.add_child(name_part)
          return name
        end
        role_node = Nokogiri::XML::Node.new('mods:role', ng_xml)
        role_code = Nokogiri::XML::Node.new('mods:roleTerm', ng_xml)
        role_code['type'] = 'code'
        role_code['authority'] = 'marcrelator'
        role_code.content = code
        role_text = Nokogiri::XML::Node.new('mods:roleTerm', ng_xml)
        role_text['type'] = 'text'
        role_text['authority'] = 'marcrelator'
        role_text.content = text

        name.add_child(name_part)
        role_node.add_child(role_code)
        role_node.add_child(role_text)
        name.add_child(role_node)

        name
      end

      def date_template(tag, enc, sdate, edate = nil)
        return nil unless DRI::Vocabulary.mods_date_tags.include?(tag) && !sdate.empty?

        start_date = Nokogiri::XML::Node.new("#{MODS_NS_PREFIX}:#{tag}", ng_xml)
        start_date['point'] = 'start' unless edate.nil? || edate.empty?
        start_date['encoding'] = enc unless enc.empty? || !DRI::Vocabulary.mods_date_encoding.include?(enc)
        start_date.content = sdate

        unless edate.nil? || edate.empty?
          end_date = Nokogiri::XML::Node.new("#{MODS_NS_PREFIX}:#{tag}", ng_xml)
          end_date['point'] = 'end'
          end_date['encoding'] = enc unless enc.empty? || !DRI::Vocabulary.mods_date_encoding.include?(enc)
          end_date.content = edate

          return [start_date, end_date]
        end

        [start_date]
      end

      def rights_template(content, note = '', status = '')
        rights_node = Nokogiri::XML::Node.new("#{MODS_NS_PREFIX}:accessCondition", ng_xml)
        rights_node['type'] = 'use and reproduction'

        copyright_md = Nokogiri::XML::Node.new("#{CR_NS_PREFIX}:copyright", ng_xml)
        copyright_md['copyright.status'] = status unless status.empty?
        holder = Nokogiri::XML::Node.new("#{CR_NS_PREFIX}:rights.holder", ng_xml)
        holder.content = content
        copyright_md.add_child(holder)

        unless note.empty?
          rights_note = Nokogiri::XML::Node.new("#{CR_NS_PREFIX}:general.note", ng_xml)
          rights_note.content = note
          copyright_md.add_child(rights_note)
        end

        rights_node.add_child(copyright_md)

        rights_node
      end

      def retrieve_terms_hash
        terms_hash = {}
        terms_hash[:title] = title

        # Creator, contributor and any name
        names_hash = { 'name' => [], 'type' => [], 'authority' => [] }
        names_xpath = '/mods:mods/mods:name'
        ng_xml.search(names_xpath, { 'xmlns:mods' => MODS_NS }).each do |node|
          part_node = node.at('./mods:namePart', { 'xmlns:mods' => MODS_NS })
          role_code = node.at('./mods:role/mods:roleTerm[@type="code"]', { 'xmlns:mods' => MODS_NS })
          next if part_node.nil? || role_code.nil?
          next if role_code.nil? || DRI::Vocabulary.marc_relators_creator.key?(role_code.content)

          names_hash['authority'] << (node['authority'] ? node['authority'] : '')
          names_hash['name'] << part_node.content
          names_hash['type'] << role_code.content.prepend('role_')
        end
        terms_hash[:roles] = names_hash

        terms_hash[:desc_abstract] = desc_abstract
        terms_hash[:desc_toc] = desc_toc
        terms_hash[:desc_note] = desc_note
        terms_hash[:desc_physdesc_note] = desc_physdesc_note
        terms_hash[:rights] = rights
        terms_hash[:language] = mods_language_text

        # Type
        type_hash = { collection: collection?, content: [] }
        type_xpath = '/mods:mods/mods:typeOfResource'
        ng_xml.search(type_xpath, { 'xmlns:mods' => MODS_NS }).each do |node|
          type_hash[:content] << node.content
        end
        terms_hash[:type] = type_hash

        # Genre
        genre_hash = { authority: [], content: [] }
        genre_xpath = '/mods:mods/mods:genre'
        ng_xml.search(genre_xpath, { 'xmlns:mods' => MODS_NS }).each do |node|
          genre_hash[:content] << node.content
          genre_hash[:authority] << (node['authority'] ? node['authority'] : '')
        end

        terms_hash[:mods_genre] = genre_hash

        origin_metadata_array = []
        origin_info_nodes = ng_xml.search('/mods:mods/mods:originInfo', { 'xmlns:mods' => MODS_NS })

        origin_info_nodes.each do |origin|
          origin_info_hash = {}
          index = 0
          origin.children.select(&:element?).each do |elem|
            tag = elem.name

            case tag
            when 'place'
              place_hash = { tag: 'place', content: '' }
              p_term = elem.at('./mods:placeTerm', { 'xmlns:mods' => MODS_NS })
              place_hash[:content] = p_term.content
              origin_info_hash["#{index}"] = place_hash
              index += 1
            when 'issuance', 'publisher', 'edition', 'frequency'
              elem_hash = { tag: tag, content: elem.content }
              origin_info_hash["#{index}"] = elem_hash
              index += 1
            else
              # date
              date_hash = { tag: tag, start: '', end: '', encoding: '' }
              case elem['point']
              when 'start'
                date_hash[:start] << elem.content
                end_node = origin.children.select { |node| node.name == tag && node['point'] == 'end' }
                date_hash[:end] << end_node.first.content unless end_node.empty?
              when 'end'
                next
              else
                date_hash[:start] << elem.content
                date_hash[:end] << ''
              end
              date_hash[:encoding] << (elem['encoding'].nil? ? '' : elem['encoding'])

              origin_info_hash["#{index}"] = date_hash
              index += 1
            end
          end

          origin_metadata_array << origin_info_hash
        end
        terms_hash[:origin_metadata] = origin_metadata_array

        # Subjects: topic, name_coverage, temporal_coverage, geographical_coverage
        subjects_array = []
        subject_nodes = ng_xml.search('/mods:mods/mods:subject', { 'xmlns:mods' => MODS_NS })
        subject_nodes.each do |snode|
          subj_hash = { values: [], authority: '' }

          subj_hash[:authority] = snode[:authority] unless snode[:authority].nil?
          snode.children.select(&:element?).each do |node|
            tag = node.name

            case tag
            when 'topic'
              topic_hash = { tag: tag, content: node.content }
              subj_hash[:values] << topic_hash
            when 'name'
              name_hash = { tag: tag, display: '', role: '' }
              node_name = node.at('./mods:namePart', { 'xmlns:mods' => MODS_NS })

              next if node_name.nil?

              name_hash[:display] = node_name.content
              node_role = node.at('./mods:role/mods:roleTerm[@type="code"]', { 'xmlns:mods' => MODS_NS })
              name_hash[:role] = node_role.content unless node_role.nil?

              subj_hash[:values] << name_hash
            when 'temporal'
              temporal_hash = { tag: tag, start: '', end: '', encoding: '' }
              case node['point']
              when 'start'
                temporal_hash[:start] = node.content
                end_node = snode.children.select { |n| n['point'] == 'end' }
                temporal_hash[:end] = end_node.first.content unless end_node.empty?
              when 'end'
                next
              else
                temporal_hash[:start] = node.content
              end
              temporal_hash[:encoding] = node[:encoding] unless node[:encoding].nil?

              subj_hash[:values] << temporal_hash
            when 'geographic'
              geo_hash = { tag: tag, content: node.content }
              if node['authority'].present? && node['authority'] == 'logainm'
                geo_hash[:uri] = node['valueURI'] if node['valueURI'].present?
              end
              subj_hash[:values] << geo_hash
            else
              next
            end
          end # specific subject elements

          subjects_array << subj_hash
        end # all subjects
        terms_hash[:subject_metadata] = subjects_array

        terms_hash
      end

      def validate_dates(origin_node, date_tag)
        date_nodes = origin_node.children.select { |node| node.local_name == date_tag }

        return true if date_nodes.empty?

        start_count = 0
        end_count = 0
        date_nodes.each do |date|
          start_count += 1 unless date['point'] == 'start'
          end_count += 1 unless date['point'] == 'end'

          break if start_count > 1 || end_count > 1
        end

        start_count == end_count && start_count <= 1 ? true : false
      end

      def validate_all_dates
        origin_nodes = ng_xml.search('//mods:originInfo', { 'xmlns:mods' => MODS_NS })

        origin_nodes.each do |node|
          valid_created = validate_dates(node, 'mods:dateCreated')
          valid_issued = validate_dates(node, 'mods:dateIssued')

          if !valid_created || !valid_issued
            Rails.logger.error('MODS validate_all_dates: invalid date found in metadata record.')
            return false
          end
        end

        true
      end

      def custom_validations
        errors = {}

        creator_result = false
        identifier_result = false
        uri_result = true
        ext_uri_result = true
        title_result = false
        description_result = false
        rights_result = false
        type_result = false
        date_result = false

        creator_result = true if creator.any? { |v| !v.blank? }

        unless creator_result == true
          marc_rels = *(DRI::Vocabulary.marc_relators.map { |s| s.prepend('role_').to_sym })

          marc_rels.each do |role|
            res = send(role).any? { |v| !v.blank? }
            creator_result = true if res
            break if res
          end
        end
        # This is the mods identifier used internally in DRI:
        # uniquely identify a record/relationships management
        identifier_result = true if mods_id_local.any? { |v| !v.blank? }
        identifier_uri.each { |value| uri_result = false unless !value.blank? && Utils.valid_uri?(value) }
        # Check that for external relationships terms, the specified URIs are valid
        related_items_digital.each do |value|
          ext_uri_result = false unless !value.blank? && Utils.valid_uri?(value)
        end
        title_result = true if title.any? { |v| !v.blank? }
        description_result = true if description.any? { |v| !v.blank? }
        rights_result = true if rights.any? { |v| !v.blank? }
        type_result = true if type.any? { |v| !v.blank? }

        unless type_result == true
          type_result = true if mods_genre.any? { |v| !v.blank? }
        end

        # Creation date can either be: dateCreated, dateIssued,
        # dateCaptured (in this priority order)
        date_result = true if creation_date.any? { |v| !v.blank? }
        dates_array = [creation_date_start, published_date, issued_date_start, captured_date,
                       captured_date_start, other_date, other_date_start]
        unless date_result
          dates_array.each do |dates|
            res = dates.any? { |v| !v.blank? }
            date_result = true if res
            break if res
          end
        end

        errors[:mods_id_local] = 'not present.' unless identifier_result == true
        errors[:identifier_uri] = 'invalid URI present' unless uri_result == true
        errors[:related_items_digital] = 'invalid URI present' unless ext_uri_result == true
        errors[:title] = "can\'t be blank" if title_result == false
        errors[:type] = "can\'t be blank" if type_result == false

        # If this is a collection then validate:
        # return errors unless mods_type_collection.present?

        errors[:creator] = "can\'t be blank" if creator_result == false
        errors[:description] = "can\'t be blank" if description_result == false
        errors[:rights] = "can\'t be blank" if rights_result == false
        errors[:creation_date] = "can\'t be blank" if date_result == false

        errors
      end # custom_validations
    end # class
  end # module
end # module
