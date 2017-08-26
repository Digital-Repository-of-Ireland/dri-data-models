module DRI::Metadata::Terminologies
  module Marc

      def load_inherited_terminology
        # Set OM (Opinionated Metadata) terminology
        # OM terminology mapping to a Marc Collection
        # df=datafield, sf=subfield
        set_terminology do |t|
          t.root(path: 'record', namespace_prefix: nil)

          t.record(path: 'record', namespace_prefix: nil) {

            t.leader(path: 'leader', namespace_prefix: nil, index_as: [DRI::Metadata::Descriptors.cleaned_searchable,DRI::Metadata::Descriptors.cleaned_displayable])

            t.controlfield {
              t.controlfield_tag(path: { attribute: 'tag' })
            }

            t.datafield {
              t.tag(path: { attribute: 'tag' })
              t.ind1(path: { attribute: 'ind1' })
              t.ind2(path: { attribute: 'ind2' })
              t.subfield(path: 'subfield') {
                t.code(path: { attribute: 'code' })
              }
            }
          }

          # TERM PROXIES and mappings
          # Mandatory fields
          t.title(path: 'record/datafield[@tag="245"]/subfield[@code="a" or @code="b" or @code="c"]', index_as: [DRI::Metadata::Descriptors.cleaned_searchable,DRI::Metadata::Descriptors.cleaned_displayable])
          t.description(path: 'record/datafield[@tag="300" or @tag="500" or @tag="520"]', index_as: [DRI::Metadata::Descriptors.cleaned_searchable,DRI::Metadata::Descriptors.cleaned_displayable])
          t.creator(path: 'record/datafield[@tag="100" or @tag="110" or @tag="700" or @tag="710" or @tag="711"]', index_as: [DRI::Metadata::Descriptors.cleaned_searchable,DRI::Metadata::Descriptors.cleaned_displayable])
          t.rights(path: 'record/datafield[@tag="506" or @tag="540"] | //record/datafield[@tag="542"]/subfield[@code="f"]', index_as: [DRI::Metadata::Descriptors.cleaned_searchable,DRI::Metadata::Descriptors.cleaned_displayable])
          t.date_260c_264c(path: 'record/datafield[@tag="260" or @tag="264"]/subfield[@code="c"]')
          
          # common fields
          t.language(path: 'record/datafield[@tag="041"]/subfield[@code="a"]', index_as: [DRI::Metadata::Descriptors.cleaned_searchable,DRI::Metadata::Descriptors.language_facetable])
          t.publisher(path: 'record/datafield[@tag="260"]/subfield[@code="b"] | //record/datafield[@tag="710"]/subfield[@code="x"]', index_as: [DRI::Metadata::Descriptors.cleaned_searchable,DRI::Metadata::Descriptors.cleaned_facetable,DRI::Metadata::Descriptors.cleaned_displayable])
          t.author(path: 'record/datafield[@tag="100" or @tag="110" or @tag="111"]/subfield[@code="a"] | //record/datafield[@tag="740"]/subfield[@code="a"]', index_as: [DRI::Metadata::Descriptors.cleaned_searchable,DRI::Metadata::Descriptors.cleaned_displayable,DRI::Metadata::Descriptors.cleaned_facetable])
          t.subject(path: 'record/datafield[@tag="600" or @tag="610" or @tag="611" or @tag="630" or @tag="650" or @tag="653"]/subfield[@code="a"]', index_as: [DRI::Metadata::Descriptors.cleaned_searchable,DRI::Metadata::Descriptors.cleaned_facetable,DRI::Metadata::Descriptors.cleaned_displayable])
          t.contributor(path: 'record/datafield[@tag="700"]/subfield[@code="a"]', index_as: [DRI::Metadata::Descriptors.cleaned_searchable,DRI::Metadata::Descriptors.cleaned_displayable])
          # TODO Add mapping to Source
          t.source(path: 'record/datafield[@tag="830" or @tag="490"]/subfield[@code="a"]', index_as: [DRI::Metadata::Descriptors.cleaned_searchable,DRI::Metadata::Descriptors.cleaned_displayable])
          # marc fields
          t.leader(proxy: [:record, :leader])

          # Controlfields
          t.controlfield(ref: [:record, :controlfield])
          t.controlfield_tag(proxy: [:record, :controlfield, :controlfield_tag])
          # Datafields
          t.datafield(ref: [:record, :datafield])
          t.datafield_tag(proxy: [:record, :datafield, :tag])
          t.datafield_ind1(proxy: [:record, :datafield, :ind1])
          t.datafield_ind2(proxy: [:record, :datafield, :ind2])

          @marc ||= YAML.load(File.read(File.expand_path('../../../vocabulary_marc.yaml', __FILE__)))
          @marc[:controlfield].each do |cf|
            t.send("cf_#{cf[1][:tag]}",
                   path: "record/controlfield[@tag='#{cf[1][:tag]}']",
                   index_as: [DRI::Metadata::Descriptors.cleaned_searchable,DRI::Metadata::Descriptors.cleaned_displayable,DRI::Metadata::Descriptors.cleaned_facetable])
          end

          @marc[:datafield].each do |section|
            section[1].each do |df|
              df[1][:subfield].each do |sf|
                t.send("df_#{df[1][:tag]}#{sf[1][:code]}",
                       path: "record/datafield[@tag='#{df[1][:tag]}']/subfield[@code='#{sf[1][:code]}']",
                       index_as: [DRI::Metadata::Descriptors.cleaned_searchable,DRI::Metadata::Descriptors.cleaned_displayable,DRI::Metadata::Descriptors.cleaned_facetable])
              end
            end
          end

          # NCCB Specific fields and overrides
          t.nccb_catalog_author(path: 'record/datafield[@tag="100" or @tag="110" or @tag="111"]/subfield[@code="a"]', index_as: [DRI::Metadata::Descriptors.cleaned_searchable,DRI::Metadata::Descriptors.cleaned_displayable])
          t.nccb_add_title_info(path: 'record/datafield[@tag="130" or @tag="246"]/subfield[@code="a"]', index_as: [DRI::Metadata::Descriptors.cleaned_searchable,DRI::Metadata::Descriptors.cleaned_displayable])
          t.nccb_other_names(path: 'record/datafield[@tag="700" or @tag="720"]/subfield[@code="a"]', index_as: [DRI::Metadata::Descriptors.cleaned_searchable,DRI::Metadata::Descriptors.cleaned_displayable])
          t.nccb_notes(path: 'record/datafield[@tag="500" or @tag="501" or @tag="503" or @tag="504" or @tag="505" or @tag="508" or @tag="510" or @tag="514" or @tag="520"  or @tag="521" or @tag="524" or @tag="530" or @tag="531" or @tag="546" or @tag="586"]/subfield[@code="a"]', index_as: [DRI::Metadata::Descriptors.cleaned_searchable,DRI::Metadata::Descriptors.cleaned_displayable])
          t.nccb_subject(path: 'record/datafield[@tag="600" or @tag="610" or @tag="611" or @tag="653"]/subfield[@code="a"]', index_as: [DRI::Metadata::Descriptors.cleaned_searchable,DRI::Metadata::Descriptors.cleaned_displayable])
          # NCCB specific Facets
          t.nccb_subject_facet(path: 'record/datafield[@tag="600" or @tag="610" or @tag="611"]/subfield[@code="a"]', index_as: [DRI::Metadata::Descriptors.cleaned_searchable,DRI::Metadata::Descriptors.cleaned_facetable,DRI::Metadata::Descriptors.cleaned_displayable])

          # Date Indices
          t.date_idx(path: '//record/controlfield[@tag="008"]')

          # marc_id is used as a local, unique identifier for the record and is used for internal DRI relationships specified in the metadata
          # we map it to 024 - Other Standard Identifier (R)
          # Standard number or code published on an item which cannot be accommodated in another field
          # The type of standard number or code is identified in the first indicator position or in subfield $2 (Source of number or code)
          # Full map: tag 024; first indicator 7 (Source specified in subfield $2), subfield $2 contains a value of 'local' (from http://www.loc.gov/standards/sourcelist/standard-identifier.html)
          # value of the identifier comes then from subfield $a
          # Example: 024  7#$a0A3200912B4A1057$2local http://www.loc.gov/marc/marc2dc.html#unqualifiedlist
          t.marc_id(path: 'record/datafield[@tag="024" and @ind1="7" and subfield[@code="2"]="local"]/subfield[@code="a"]',
            index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])

          # marc_asset - Used for sorting sequenced items
          # we map it to 024 - Other Standard Identifier (R); indicator1 = 8 (Unspecified type of standard number or code)
          t.id_asset(path: 'record/datafield[@tag="024" and @ind1="8"]/subfield[@code="a"]', index_as: :stored_sortable)
          
          # Relationships terms (Crosswalk MARC to QDC: http://www.loc.gov/marc/marc2dc.html#qualifiedlist)
          # Tag 775 - Other Edition Entry (R); Subfield $o - Other item identifier (R)
          t.relation_ids_isVersionOf(path: 'record/datafield[@tag="775"]/subfield[@code="o"]',
            index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])
          # Tag 776 - Additional Physical Form Entry (R); Subfield $o - Other item identifier (R)
          t.relation_ids_isFormatOf(path: 'record/datafield[@tag="776"]/subfield[@code="o"]',
            index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])
          # Tag 787 - Other Relationship Entry (R); Subfield $o - Other item identifier (R)
          t.relation_ids_relation(path: 'record/datafield[@tag="787"]/subfield[@code="o"]',
            index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])
          # Tag 780 - Preceding Entry (R); Subfield $o - Preceding item identifier (R)
          t.relation_ids_preceding(path: 'record/datafield[@tag="780"]/subfield[@code="o"]',
            index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])
          # Tag 785 - Succeeding Entry (R); Subfield $o - Succeeding item identifier (R)
          t.relation_ids_succeeding(path: 'record/datafield[@tag="785"]/subfield[@code="o"]',
            index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])
          # FIXME: Related Material is also mapped to alternative_form
          t.related_material(path: 'record/datafield[@tag="530"]/subfield[@code="u"]',
            index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])
          # MARC field 530, subfield $u for a URL to an alternative form available of this resource
          t.alternative_form(path: "record/datafield[@tag='530']/subfield[@code='u']",
            index_as: [DRI::Metadata::Descriptors.cleaned_searchable, DRI::Metadata::Descriptors.cleaned_displayable])
        end # set_terminology
      end

    end
  end