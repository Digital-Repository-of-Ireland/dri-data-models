module DRI::Metadata::Terminologies
  module Qdc
    # Set OM (Opinionated Metadata) terminology
    def load_inherited_terminology
      set_terminology do |t|
        t.root(path: '*') # Selects the root node of the XML document

        # Simple Dublin Core Fields
        t.title(namespace_prefix: 'dc', index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable]) {
          t.title_lang(path: { attribute: 'xml:lang' })
        }
        t.rights(namespace_prefix: 'dc', index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable]) {
          t.rights_lang(path: { attribute: 'xml:lang' })
        }
        t.description(namespace_prefix: 'dc', index_as: [DRI::Metadata::Descriptors.cleaned_searchable]) {
          t.description_lang(path: { attribute: 'xml:lang' })
        }
        t.language(namespace_prefix: 'dc', index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.language_facetable])
        t.subject(namespace_prefix: 'dc', index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_facetable, DRI::Metadata::Descriptors.cleaned_displayable]) {
          t.subject_lang(path: { attribute: 'xml:lang' })
        }
        t.subject_lang(proxy: [:subject, :subject_lang])
        t.date(namespace_prefix: 'dc')
        t.contributor(path: 'contributor', namespace_prefix: 'dc', index_as: [DRI::Metadata::Descriptors.cleaned_facetable, DRI::Metadata::Descriptors.cleaned_searchable])
        t.source(path: 'source', namespace_prefix: 'dc', index_as: [DRI::Metadata::Descriptors.cleaned_searchable]) {
          t.source_lang(path: { attribute: 'xml:lang' })
        }
        t.publisher(path: 'publisher', namespace_prefix: 'dc', index_as: [DRI::Metadata::Descriptors.cleaned_facetable, DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])
        t.coverage(namespace_prefix: 'dc', index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable]) {
          t.coverage_lang(path: { attribute: 'xml:lang' })
        }
        t.relation(namespace_prefix: 'dc', index_as: [DRI::Metadata::Descriptors.cleaned_displayable, DRI::Metadata::Descriptors.cleaned_facetable])
        t.external_relation(ref: :relation, attributes: { 'xsi:type' => 'dcterms:URI' }, index_as: [DRI::Metadata::Descriptors.cleaned_displayable, DRI::Metadata::Descriptors.cleaned_facetable])

        t.creator(namespace_prefix: 'dc', index_as: [DRI::Metadata::Descriptors.cleaned_facetable, DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable, :sortable])
        t.format(namespace_prefix: 'dc', index_as: [DRI::Metadata::Descriptors.cleaned_facetable,
             DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])
        t.resource_type(path: 'type', namespace_prefix: 'dc', index_as: [DRI::Metadata::Descriptors.cleaned_facetable,
             DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])

        t.identifier(namespace_prefix: 'dc')
        # FIRST DC IDENTIFIER can be used for sorting in the UI, same as MODS and MARC
        t.id_asset(path: 'identifier[1]', namespace_prefix: 'dc', index_as: [:stored_sortable])
        # Used for QDC metadata relationships, as the local, unique record ID
        t.qdc_id(ref: :identifier, index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])

        # Qualified Dublin Core fields
        t.published_date(path: 'issued', namespace_prefix: 'dcterms')
        t.creation_date(path: 'created', namespace_prefix: 'dcterms')
        t.geographical_coverage(path: 'spatial', namespace_prefix: 'dcterms', index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable]) {
          t.geographical_coverage_lang(path: { attribute: 'xml:lang' })
        }
        t.temporal_coverage(path: 'temporal', namespace_prefix: 'dcterms') {
          t.temporal_coverage_lang(path: { attribute: 'xml:lang' })
        }
        t.geocode_point(ref: :geographical_coverage, attributes: { 'xsi:type' => 'dcterms:Point' }, index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])
        t.geocode_box(ref: :geographical_coverage, attributes: { 'xsi:type' => 'dcterms:Box' }, index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])
        t.name_coverage(path: 'dpc', namespace_prefix: 'marcrel', index_as: [DRI::Metadata::Descriptors.cleaned_facetable,
             DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable]) {
          t.name_coverage_lang(path: { attribute: 'xml:lang' })
        }

        # Generate MARC Relators fields from the MARC Relators vocabulary
        DRI::Vocabulary.marc_relators.each do |role|
          t.send "role_#{role}",
                 path: role,
                 namespace_prefix: 'marcrel',
                 index_as: [DRI::Metadata::Descriptors.cleaned_facetable, DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable]
        end

        # Relationships for QDC
        DRI::Vocabulary.qdc_relationship_types.each do |rel|
          t.send "relation_ids_#{rel}",
                 path: rel,
                 attributes: { "xsi:type"=>:none },
                 namespace_prefix: 'dcterms',
                 index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable]
        end

        # External relationships (contain uri to a resource external to DRI)
        DRI::Vocabulary.qdc_relationship_types.each do |rel|
          t.send "ext_related_items_ids_#{rel}",
                 path: rel,
                 attributes: { 'xsi:type' => 'dcterms:URI' },
                 namespace_prefix: 'dcterms'
        end
      end
    end
  end
end
