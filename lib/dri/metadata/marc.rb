# DRI namespace
module DRI
  # Metadata namespace
  module Metadata
    # An ActiveFedora datastream that interacts with MARC-XML Metadata.
    class Marc < DRI::Metadata::Base
      # OM terminology mapping to a Marc Collection
      # df=datafield, sf=subfield
      set_terminology do |t|
        t.root(path: 'record', namespace_prefix: nil)

        t.record(path: 'record', namespace_prefix: nil) {

          t.leader(path: 'leader', namespace_prefix: nil, index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])

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
        t.title(path: 'record/datafield[@tag="245"]/subfield[@code="a" or @code="b" or @code="c"]', index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.description(path: 'record/datafield[@tag="300" or @tag="500" or @tag="520"]', index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.creator(path: 'record/datafield[@tag="100" or @tag="110" or @tag="700" or @tag="710" or @tag="711"]', index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.rights(path: 'record/datafield[@tag="506" or @tag="540"] | //record/datafield[@tag="542"]/subfield[@code="f"]', index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.creation_date(path: 'record/datafield[@tag="260" or @tag="264"]/subfield[@code="c"] | //record/controlfield[@tag="008"]', index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        
        # common fields
        t.language(path: 'record/datafield[@tag="041"]/subfield[@code="a"]', index_as: [Descriptors.cleaned_searchable, Descriptors.language_facetable])
        t.publisher(path: 'record/datafield[@tag="260"]/subfield[@code="b"] | //record/datafield[@tag="710"]/subfield[@code="x"]', index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable])
        t.published_date(path: 'record/datafield[@tag="260"]/subfield[@code="c"]', index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, :sortable])
        t.author(path: 'record/datafield[@tag="100" or @tag="110" or @tag="111"]/subfield[@code="a"] | //record/datafield[@tag="740"]/subfield[@code="a"]', index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable, Descriptors.cleaned_facetable])
        t.subject(path: 'record/datafield[@tag="600" or @tag="610" or @tag="611" or @tag="630" or @tag="650" or @tag="653"]/subfield[@code="a"]', index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable])
        t.contributor(path: 'record/datafield[@tag="700"]/subfield[@code="a"]', index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        # TODO Add mapping to Source
        t.source(path: 'record/datafield[@tag="830" or @tag="490"]/subfield[@code="a"]', index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
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

        @marc ||= YAML.load(File.read(File.expand_path('../../vocabulary_marc.yaml', __FILE__)))
        @marc[:controlfield].each do |cf|
          t.send("cf_#{cf[1][:tag]}",
                 path: "record/controlfield[@tag='#{cf[1][:tag]}']",
                 index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable, Descriptors.cleaned_facetable])
        end

        @marc[:datafield].each do |section|
          section[1].each do |df|
            df[1][:subfield].each do |sf|
              t.send("df_#{df[1][:tag]}#{sf[1][:code]}",
                     path: "record/datafield[@tag='#{df[1][:tag]}']/subfield[@code='#{sf[1][:code]}']",
                     index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable, Descriptors.cleaned_facetable])
            end
          end
        end

        # NCCB Specific fields and overrides
        t.nccb_catalog_author(path: 'record/datafield[@tag="100" or @tag="110" or @tag="111"]/subfield[@code="a"]', index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.nccb_add_title_info(path: 'record/datafield[@tag="130" or @tag="246"]/subfield[@code="a"]', index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.nccb_other_names(path: 'record/datafield[@tag="700" or @tag="720"]/subfield[@code="a"]', index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.nccb_notes(path: 'record/datafield[@tag="500" or @tag="501" or @tag="503" or @tag="504" or @tag="505" or @tag="508" or @tag="510" or @tag="514" or @tag="520"  or @tag="521" or @tag="524" or @tag="530" or @tag="531" or @tag="546" or @tag="586"]/subfield[@code="a"]', index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.nccb_subject(path: 'record/datafield[@tag="600" or @tag="610" or @tag="611" or @tag="653"]/subfield[@code="a"]', index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        # NCCB specific Facets
        t.nccb_subject_facet(path: 'record/datafield[@tag="600" or @tag="610" or @tag="611"]/subfield[@code="a"]', index_as: [Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable])

        # Date Indices
        t.creation_date_idx(path: '//record/controlfield[@tag="008"]')

        # marc_id is used as a local, unique identifier for the record and is used for internal DRI relationships specified in the metadata
        # we map it to 024 - Other Standard Identifier (R)
        # Standard number or code published on an item which cannot be accommodated in another field
        # The type of standard number or code is identified in the first indicator position or in subfield $2 (Source of number or code)
        # Full map: tag 024; first indicator 7 (Source specified in subfield $2), subfield $2 contains a value of 'local' (from http://www.loc.gov/standards/sourcelist/standard-identifier.html)
        # value of the identifier comes then from subfield $a
        # Example: 024 	7#$a0A3200912B4A1057$2local http://www.loc.gov/marc/marc2dc.html#unqualifiedlist
        t.marc_id(path: 'record/datafield[@tag="024" and @ind1="7" and subfield[@code="2"]="local"]/subfield[@code="a"]')
        # marc_asset - Used for sorting sequenced items
        # we map it to 024 - Other Standard Identifier (R); indicator1 = 8 (Unspecified type of standard number or code)
        t.id_asset(path: 'record/datafield[@tag="024" and @ind1="8"]/subfield[@code="a"]')

        # Relationships terms (Crosswalk MARC to QDC: http://www.loc.gov/marc/marc2dc.html#qualifiedlist)
        # Tag 775 - Other Edition Entry (R); Subfield $o - Other item identifier (R)
        t.relation_ids_isVersionOf(path: 'record/datafield[@tag="775"]/subfield[@code="o"]')
        # Tag 776 - Additional Physical Form Entry (R); Subfield $o - Other item identifier (R)
        t.relation_ids_isFormatOf(path: 'record/datafield[@tag="776"]/subfield[@code="o"]')
        # Tag 787 - Other Relationship Entry (R); Subfield $o - Other item identifier (R)
        t.relation_ids_relation(path: 'record/datafield[@tag="787"]/subfield[@code="o"]')

        # Tag 780 - Preceding Entry (R); Subfield $o - Preceding item identifier (R)
        t.relation_ids_preceding(path: 'record/datafield[@tag="780"]/subfield[@code="o"]')
        # Tag 785 - Succeeding Entry (R); Subfield $o - Succeeding item identifier (R)
        t.relation_ids_succeeding(path: 'record/datafield[@tag="785"]/subfield[@code="o"]')

        # FIXME: Related Material is also mapped to alternative_form
        t.related_material(path: 'record/datafield[@tag="530"]/subfield[@code="u"]')
        # MARC field 530, subfield $u for a URL to an alternative form available of this resource
        t.alternative_form(path: "record/datafield[@tag='530']/subfield[@code='u']")
      end # set_terminology

      # Determine whether the metadata describes a collection
      # From: Appendix 2 - Conversion rules for Leader06 - dc:Type mapping
      # http://www.loc.gov/marc/marc2dc.html
      def collection?
        # Leader/06 value for "dcmitype:collection": p (mixed materials)
        # Leader/07 value for "dcmitype:collection": c (collection)
        # xpath indices for strings start at 1
        leader_6_type = ng_xml.xpath('substring(//record/leader, 7, 1)')
        leader_7_type = ng_xml.xpath('substring(//record/leader, 8, 1)')

        (leader_6_type == 'p' || leader_7_type == 'c') ? true : false
      end

      # Returns an empty, default MARC XML template
      #
      # @return [Nokogiri::Document] the MARC XML document
      def self.xml_template
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.record('xmlns:marc' => 'http://www.loc.gov/MARC21/slim',
                     'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                     'xsi:schemaLocation' => 'http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd') {
            xml.leader
            xml.controlfield(tag: '')
            xml.datafield(tag: '', ind1: '#', ind2: '#') {
              xml.subfield(code: '')
            }
          }
        end

        builder.doc
      end

      # Override from AF Solrizer for datastreams
      # Update solr_doc Hash for index into Solr from the metadata
      # @param [Hash] solr_doc the solr document hash
      # @param [Hash] opts additional custom options
      # @return [Hash] the updated solr_doc hash for Solr index
      def to_solr(solr_doc = {}, opts = {})
        solr_doc = super(solr_doc, opts)

        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('type', :stored_searchable) => type)
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('type', :facetable) => type)

        # Retrieve list of all people and add to
        # facet and search indexes in solr document
        person_array = person_array_for_index

        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('person', :facetable) => person_array)
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('person', :stored_searchable, type: :text) => person_array | DRI::Metadata::Transformations.transform_name(person_array))

        # Index Creator with null fields removed
        solr_doc = remove_null_values(solr_doc, 'creator') if solr_doc[ActiveFedora.index_field_mapper.solr_name('creator', :stored_searchable)].present?

        # all_metadata - A SOLR index of all the text
        # contained in the XML document
        all_metadata = ''
        ng_xml.xpath('//text()').each do |text_node|
          all_metadata += text_node.text
          all_metadata += ' '
        end
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('all_metadata', :stored_searchable, type: :text) => [all_metadata])

        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('title_sorted', :stored_sortable, type: :string) => df_240a)
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('author_sorted', :stored_sortable, type: :string) => df_100a)
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('library_sorted', :stored_sortable, type: :string) => df_850a)

        date_ranges = creation_date_for_index # ALL the date ranges

        # Creation date dateRange index
        cdate_ranges = date_ranges.select { |key, _value| ['creation_date'].include?(key) }
        solr_doc.merge!(DRI::Metadata::Transformations::CREATION_DATE_RANGE_SOLR_FIELD => DRI::Metadata::Transformations.transform_date_ranges(cdate_ranges)) unless cdate_ranges.empty?

        solr_doc
      end

      # Returns all metadata related to people names for Solr indexing
      # People facet
      # @return [Array<String>] array of all people names metadata values for Solr indexing
      def person_array_for_index
        contributor | creator | publisher
      end

      # Returns all metadata related to creation date for Solr indexing
      # @return [Hash] the hash with creation_date array
      def creation_date_for_index
        dates_hash = {}

        return dates_hash if creation_date_idx.empty?

        dates_array = creation_date_idx.map do |value|
          date_s = value.slice(7, 4)
          date_e = value.slice(11, 4)
          unless ['\\\\', '    ', '####'].include?(date_s)
            ['\\\\', '    ', '####'].include?(date_e) ? date_s : "#{date_s}/#{date_e}"
          end
        end

        dates_hash['creation_date'] = dates_array unless dates_array.empty?

        dates_hash
      end

      # Implement additional DRI metadata validations as this class does not inherit
      # from DRI::Metadata::Base
      # @return [Hash] the hash with any errors from validation
      def custom_validations
        errors = {}

        title_result = false
        type_result = false
        description_result = false
        creator_result = false
        rights_result = false
        creation_date_result = false

        # Join all elements in array, get rid of carriage returns from the form (squish) and validate
        title_result = true unless title.join.squish.empty?
        type_result = true unless type.join.squish.empty?
        description_result = true unless description.join.squish.empty?
        creator_result = true unless creator.join.squish.empty?
        rights_result = true unless rights.join.squish.empty?
        creation_date_result = true unless creation_date.join.squish.empty?

        title_result = true if title.any? { |v| !v.blank? }
        type_result = true if type.any? { |v| !v.blank? }
        description_result = true if description.any? { |v| !v.blank? }
        creator_result = true if creator.any? { |v| !v.blank? }
        rights_result = true if rights.any? { |v| !v.blank? }
        creation_date_result = true if creation_date.any? { |v| !v.blank? }

        errors[:title] = "can\'t be blank" if title_result == false
        errors[:type] = "can\'t be blank" if type_result == false
        errors[:description] = "can\'t be blank" if description_result == false
        errors[:creator] = "can\'t be blank" if creator_result == false
        errors[:creation_date] = "can\'t be blank" if creation_date_result == false
        errors[:rights] = "can\'t be blank" if rights_result == false

        errors
      end

      # Returns the type values from the metadata
      # @return [Array<String>] the array of type values
      def type
        [DRI::Vocabulary.marc_type_leader_6[ng_xml.xpath('substring(//leader, 7, 1)')]]
      end

      # Creates the MARC datafield XML elements.
      # Used when updating the MARC metadata via attribute accessors (marc:datafield)
      # @param [Array<String>] datafields array of values for creating marc:datafield XML elements
      def add_datafields(datafields)
        ng_xml.search('//datafield').each(&:remove)

        record = ng_xml.at('record')

        datafields.each do |datafield|
          node = Nokogiri::XML::Node.new('datafield', ng_xml)
          node['tag'] = datafield['datafield_tag'].first
          node['ind1'] = datafield['datafield_ind1'].first
          node['ind2'] = datafield['datafield_ind2'].first

          datafield['subfield'].each do |subfield|
            subfield_node = Nokogiri::XML::Node.new('subfield', ng_xml)
            subfield_node['code'] = subfield['subfield_code'].first
            subfield_node.content = subfield['subfield_value'].first

            node.add_child(subfield_node) unless subfield_node.content.blank?
          end

          record.add_child(node) unless node.children.empty?
        end
      end

      # Creates the MARC controlfields XML elements.
      # Used when updating the MARC metadata via attribute accessors (marc:controlfields)
      # @param [Array<String>] controlfields array of values for creating marc:controlfields XML elements
      def add_controlfields(controlfields)
        ng_xml.search('//controlfield').each(&:remove)
        record = ng_xml.at('record')

        controlfields.each do |controlfield|
          node = Nokogiri::XML::Node.new('controlfield', ng_xml)
          node['tag'] = controlfield['controlfield_tag'].first
          node.content = controlfield['controlfield_value'].first

          record.add_child(node) unless node.content.blank?
        end
      end

      # Loads the MARC Vocabulary from the YAML file
      #
      def self.marc_vocabulary
        @marc ||= YAML.load(File.read(File.expand_path('../../vocabulary_marc.yaml', __FILE__)))
      end
    end
  end
end
