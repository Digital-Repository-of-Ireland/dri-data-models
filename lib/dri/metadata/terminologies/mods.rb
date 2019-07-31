module DRI::Metadata::Terminologies
  module Mods
    MODS_NS_PREFIX = 'mods'
    # The MODS XSD namespace URL
    MODS_NS = 'http://www.loc.gov/mods/v3'
    # The MODS XSD schema location
    MODS_SCHEMA = 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-5.xsd'
    # copyrightMD prefix for the copyrightMD XSD namespace
    CR_NS_PREFIX = 'copyrightMD'
    # The copyrightMD XSD namespace URL
    CR_NS = 'http://www.cdlib.org/inside/diglib/copyrightMD'

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # MODS prefix for the MODS XSD namespace

      def load_inherited_terminology
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

          t.abstract(path: 'abstract', index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable],
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
                  index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])
          # Creator
          t.creator(path: 'mods/mods:name[mods:role/mods:roleTerm/@authority="marcrelator" and mods:role/mods:roleTerm/@type="code" and (mods:role/mods:roleTerm[@type="code" and @authority="marcrelator"] = "cre")]/mods:namePart',
                    index_as: [DRI::Metadata::Descriptors.cleaned_facetable, DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable, :sortable],
                    namespace_prefix: MODS_NS_PREFIX)
          # Contributor
          t.contributor(path: 'mods/mods:name[mods:role/mods:roleTerm/@authority="marcrelator" and (mods:role/mods:roleTerm = "ctb")]/mods:namePart',
                        index_as: [DRI::Metadata::Descriptors.cleaned_facetable, DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable, :sortable],
                        namespace_prefix: MODS_NS_PREFIX)

          # Description: abstract, tableOfContents, or note
          t.description(path: '//mods:mods/mods:abstract | //mods:mods[not(mods:abstract)]/mods:note | //mods:mods[not(mods:abstract) and not(mods:note)]/mods:tableOfContents | //mods:mods[not(mods:abstract) and not(mods:note) and not(mods:tableOfContents)]/mods:physicalDescription/mods:note',
                        index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])
          t.desc_abstract(proxy: [:mods, :abstract], index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])
          t.desc_note(proxy: [:mods, :note], index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])
          t.desc_toc(proxy: [:mods, :table_contents], index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])
          t.desc_physdesc_note(proxy: [:mods, :physical_description, :phys_desc_note], index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])

          # Subject: defaults to subject/topic
          t.subject(proxy: [:mods, :main_subject, :subject_topic],
                    index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_facetable, DRI::Metadata::Descriptors.cleaned_displayable])

          # language
          t.language(proxy: [:mods, :language_any, :language_code],
                     index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.language_facetable])
          t.mods_language_text(proxy: [:mods, :language_any, :language_text])

          # Source
          t.source(path: 'mods/mods:relatedItem[@type="original"]/mods:location/mods:physicalLocation | mods/mods:relatedItem[@type="original" and not(mods:location)]/mods:titleInfo/mods:title',
                   index_as: [DRI::Metadata::Descriptors.cleaned_displayable, DRI::Metadata::Descriptors.cleaned_facetable],
                   namespace_prefix: MODS_NS_PREFIX)
          t.source_location(proxy: [:mods, :related_item_original, :ri_location, :location_title])
          t.source_physical_location(proxy: [:mods, :related_item_original, :ri_location, :physical_location])

          # Type
          t.resource_type(proxy: [:mods, :type_resource],
                 index_as: [DRI::Metadata::Descriptors.cleaned_facetable, DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])
          t.mods_type_collection(proxy: [:mods, :type_resource_collection])
          t.mods_genre(proxy: [:mods, :genre])

          # Rights - the type attribute with value 'use and reproduction' is DRI compulsory
          t.rights(proxy: [:mods, :access_condition],
                   index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])
          t.copyrightmd_rights(proxy: [:mods, :access_condition, :copyright, :rights_holder],
                               index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])

          # Publisher
          t.publisher(proxy: [:mods, :origin_info, :publisher],
                      index_as: [DRI::Metadata::Descriptors.cleaned_facetable, DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])

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
                                  index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable],
                                  namespace_prefix: MODS_NS_PREFIX)

          t.mods_geographic_code(proxy: [:mods, :main_subject, :subject_geographic_code], namespace_prefix: MODS_NS_PREFIX)

          # Roles proxy, similar to QDC
          DRI::Vocabulary.marc_relators.each do |role|
            if DRI::Vocabulary.marc_relators_index? role
              # Marc_relators that can be indexed
              t.send "role_#{role}",
                   path: "mods/mods:name[mods:role/mods:roleTerm/@authority='marcrelator' and mods:role/mods:roleTerm/@type='code' and mods:role/mods:roleTerm = \"#{role}\"]/mods:namePart[not(@type=\"date\")]",
                   index_as: [DRI::Metadata::Descriptors.cleaned_facetable, DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable],
                   namespace_prefix: MODS_NS_PREFIX
            else
              # create marc relator terms but do not index them
              t.send "role_#{role}",
                     path: "mods/mods:name[mods:role/mods:roleTerm/@authority='marcrelator' and mods:role/mods:roleTerm/@type='code' and mods:role/mods:roleTerm = \"#{role}\"]/mods:namePart[not(@type=\"date\")]",
                     namespace_prefix: MODS_NS_PREFIX
            end
          end

          # MODS Terms
          t.mods_id_local(proxy: [:mods, :identifier_local],
                          index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable],
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
                   namespace_prefix: MODS_NS_PREFIX,
                   index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable]
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
      end
    end
  end
end

