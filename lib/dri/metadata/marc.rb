module DRI
  # Metadata namespace
  module Metadata
    # A datastream that interacts with MARC-XML Metadata.
    class Marc < DRI::Datastreams::OmDatastream
      include DRI::Metadata
      extend DRI::Metadata::Terminologies::Marc

      PERSONAL_NAME_CODES_100 = %w[a b c d e f g j k l n p q t u 0 1 2 4 6 7 8].freeze
      PERSONAL_NAME_CODES_700 = %w[a b c d e f g h i j k l m n o p q r s t u 0 1 2 3 4 6 7 8].freeze

      def resource_type
        ['Collection'] if collection?
      end

      # Determine whether the metadata describes a collection
      # From: Appendix 2 - Conversion rules for Leader06 - dc:Type mapping
      # http://www.loc.gov/marc/marc2dc.html
      def collection?
        # Leader/06 value for "dcmitype:collection": p (mixed materials)
        # Leader/07 value for "dcmitype:collection": c (collection)
        # xpath indices for strings start at 1
        leader_6_type = ng_xml.xpath('substring(//record/leader, 7, 1)')
        leader_7_type = ng_xml.xpath('substring(//record/leader, 8, 1)')

        leader_6_type == 'p' || leader_7_type == 'c'
      end

      def creator
        personal_names_100 | personal_names_700 | corporate_name | meeting_name
      end

      def personal_names_100
        personal_names_for_tag('100', PERSONAL_NAME_CODES_100)
      end

      def personal_names_700
        personal_names_for_tag('700', PERSONAL_NAME_CODES_700)
      end

      def personal_names_for_tag(tag, codes)
        nodes = ng_xml.xpath(%(//record/datafield[@tag="#{tag}"]))
        concat_subfields(nodes, codes)
      end

      def concat_subfields(nodes, codes)
        nodes.map do |node|
          subfields = node.children.select { |subfield| codes.include?(subfield.attribute('code')&.value) }
          subfields.map(&:text).join(' ')
        end
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

        solr_doc = index_type!(solr_doc)
        solr_doc = index_creator!(solr_doc)
        solr_doc = index_person!(solr_doc)
        solr_doc = index_identifiers!(solr_doc)
        solr_doc = index_all_metadata!(solr_doc)
        solr_doc = index_sorted_fields!(solr_doc)
        solr_doc = index_dates!(solr_doc)

        solr_doc
      end

      def identifier_array_for_index
        marc_id | id_asset
      end

      # Returns all metadata related to people names for Solr indexing
      # People facet
      # @return [Array<String>] array of all people names metadata values for Solr indexing
      def person_array_for_index
        contributor | creator | publisher
      end

      def date_array_for_index
        date | date_from_all_materials
      end

      # Transforms metadata date strings into DCMI Period encoded strings for displayable indices
      # @param [String] date_field the date string
      # @return [String] the DCMI Period encoded date string for display
      def display_date_for_index(date_field)
        date_field.collect do |value|
          next if value.blank?

          if DRI::Metadata::Transformations.dcmi_period?(value) || Utils.valid_uri?(value)
            value
          else
            # Date range in ISO8601 format?
            formatted_date = ISO8601::DateTime.new(value).strftime('%Y-%m-%d')
            DRI::Metadata::Transformations.create_dcmi_period(value, formatted_date)
          end
        rescue ISO8601::Errors::StandardError
          # DCMI Period 'name' is the md value
          DRI::Metadata::Transformations.create_dcmi_period(value)
        end
      end

      def date_from_all_materials
        return [] if all_materials_dates.empty? || %w[b c d n].include?(all_materials_dates[:type])

        type_of_date = all_materials_dates[:type]
        date1 = all_materials_dates[:date1]
        date2 = all_materials_dates[:date2]

        case type_of_date
        when 's'
          name = date1
          start_date = date1
          end_date = ''
        when 'e'
          year = date1
          month = date2.slice(0, 2)
          day = date2.slice(2, 2)

          name = "#{year}#{month}#{day}"
          start_date = "#{year}#{month}#{day}"
          end_date = ''
        when 'p'
          name = "#{date1}#{date2}"
          start_date = ''
          end_date = ''
        when 'm', 'i', 'k', 'q'
          name = "#{date1} - #{date2}"
          start_date = date1
          end_date = date2
        else
          name = "#{type_of_date}#{date1}#{date2}"
          start_date = ''
          end_date = ''
        end

        [DRI::Metadata::Transformations.create_dcmi_period(name, start_date, end_date)]
      end

      def date
        date_260c_264c | date_from_all_materials
      end

      def published_date
        return nil if all_materials_dates.empty?

        type_of_date = all_materials_dates[:type]
        date1 = all_materials_dates[:date1]
        date2 = all_materials_dates[:date2]

        case type_of_date
        when 'c'
          name = "#{date1} - #{date2}"
          start_date = date1
          end_date = ''
        when 'd'
          name = "#{date1} - #{date2}"
          start_date = date1
          end_date = date2
        else
          return nil
        end

        [DRI::Metadata::Transformations.create_dcmi_period(name, start_date, end_date)]
      end

      def all_materials_dates
        @all_materials_dates || parse_all_materials
      end

      def parse_all_materials
        tag_index = controlfield_tag.find_index('008')
        return {} if tag_index.nil?

        field_008 = controlfield[tag_index]

        {
          type: field_008[6],
          date1: field_008.slice(7, 4),
          date2: field_008.slice(11, 4)
        }
      end

      # Implement additional DRI metadata validations as this class does not inherit
      # from DRI::Metadata::Base
      # @return [Hash] the hash with any errors from validation
      def custom_validations
        errors = {}

        %i[title type description creator rights].each do |field|
          errors[field] = "can't be blank" unless metadata_present?(public_send(field))
        end

        errors[:date] = "can't be blank" unless date_present?

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
        xml, record = rebuilt_xml('//datafield')

        datafields.each do |datafield|
          node = Nokogiri::XML::Node.new('datafield', ng_xml)
          node['tag'] = datafield['datafield_tag'].first
          node['ind1'] = datafield['datafield_ind1'].first
          node['ind2'] = datafield['datafield_ind2'].first

          datafield['subfield'].each do |subfield|
            subfield_node = Nokogiri::XML::Node.new('subfield', ng_xml)
            subfield_node['code'] = subfield['subfield_code'].first
            subfield_node.content = subfield['subfield_value'].first

            node.add_child(subfield_node) if subfield_node.content.present?
          end

          record.add_child(node) unless node.children.empty?
        end

        self.content = xml.to_xml
      end

      # Creates the MARC controlfields XML elements.
      # Used when updating the MARC metadata via attribute accessors (marc:controlfields)
      # @param [Array<String>] controlfields array of values for creating marc:controlfields XML elements
      def add_controlfields(controlfields)
        xml, record = rebuilt_xml('//controlfield')

        controlfields.each do |controlfield|
          node = Nokogiri::XML::Node.new('controlfield', ng_xml)
          node['tag'] = controlfield['controlfield_tag'].first
          node.content = controlfield['controlfield_value'].first

          record.add_child(node) if node.content.present?
        end

        self.content = xml.to_xml
      end

      # Loads the MARC Vocabulary from the YAML file
      #
      def self.marc_vocabulary
        @marc ||= YAML.load(File.read(File.expand_path('../../vocabulary_marc.yaml', __FILE__)))
      end

      private

      # @return [Boolean] true if any element is non-blank, or the joined,
      #   whitespace-squished text is non-empty. (These two checks were
      #   originally duplicated per-field in custom_validations; either one
      #   being true was sufficient, so this is their equivalent OR.)
      def metadata_present?(values)
        values.join.squish.present? || values.any?(&:present?)
      end

      def date_present?
        return true if metadata_present?(date)

        published_date&.any?(&:present?) || false
      end

      # Duplicates ng_xml, strips out every node matching xpath, and returns
      # both the duplicated doc and its <record> element, ready for
      # add_datafields/add_controlfields to repopulate.
      def rebuilt_xml(xpath)
        xml = ng_xml.dup
        xml.search(xpath).each(&:remove)
        [xml, xml.at('record')]
      end

      def searchable_field(name, type: nil)
        type ? Solrizer.solr_name(name, :stored_searchable, type: type) : Solrizer.solr_name(name, :stored_searchable)
      end

      def facetable_field(name)
        Solrizer.solr_name(name, :facetable)
      end

      def sortable_field(name, type:)
        Solrizer.solr_name(name, :stored_sortable, type: type)
      end

      def index_type!(solr_doc)
        solr_doc[searchable_field('type')] = type
        solr_doc[facetable_field('type')] = type
        solr_doc
      end

      def index_creator!(solr_doc)
        solr_doc[facetable_field('creator')] = creator
        solr_doc[searchable_field('creator', type: :text)] = creator

        return solr_doc unless solr_doc[searchable_field('creator', type: :text)].present?

        remove_null_values(solr_doc, 'creator')
      end

      def index_person!(solr_doc)
        person_array = person_array_for_index

        solr_doc[facetable_field('person')] = person_array
        solr_doc[searchable_field('person', type: :text)] = person_array | DRI::Metadata::Transformations.transform_name(person_array)

        solr_doc
      end

      def index_identifiers!(solr_doc)
        solr_doc['identifier_ssim'] = identifier_array_for_index
        solr_doc
      end

      # all_metadata - A SOLR index of all the text contained in the XML document
      def index_all_metadata!(solr_doc)
        solr_doc[searchable_field('all_metadata', type: :text)] = [all_metadata_text]
        solr_doc
      end

      def all_metadata_text
        ng_xml.xpath('//text()').each_with_object(String.new) { |node, str| str << node.text << ' ' }
      end

      def index_sorted_fields!(solr_doc)
        solr_doc[sortable_field('title_sorted', type: :string)] = DRI::Metadata::Transformations.transform_title_for_sort(title.first)
        solr_doc[sortable_field('author_sorted', type: :string)] = df_100a.first if df_100a.present?
        solr_doc[sortable_field('library_sorted', type: :string)] = df_850a.first if df_850a.present?

        solr_doc
      end

      def index_dates!(solr_doc)
        solr_doc[searchable_field('date')] = display_date_for_index(date)

        p_date = published_date
        if p_date
          solr_doc[searchable_field('published_date')] = display_date_for_index(p_date)
          index_date_range!(
            solr_doc, 'published_date', p_date,
            range_field: DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_SOLR_FIELD,
            year_field: DRI::Metadata::Transformations::PUBLISHED_DATE_YEAR_SOLR_FIELD,
            start_field: DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_START_SOLR_FIELD,
            end_field: DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_END_SOLR_FIELD
          )
        end

        index_date_range!(
          solr_doc, 'date', date,
          range_field: DRI::Metadata::Transformations::DATE_RANGE_SOLR_FIELD,
          start_field: DRI::Metadata::Transformations::DATE_RANGE_START_SOLR_FIELD,
          end_field: DRI::Metadata::Transformations::DATE_RANGE_END_SOLR_FIELD
        )

        solr_doc
      end

      # Shared by the plain `date` and `published_date` blocks in
      # index_dates!, which previously duplicated this range/year/min/max
      # logic almost verbatim. year_field is optional since the plain `date`
      # block never indexed a year array, only published_date did.
      def index_date_range!(solr_doc, dates_key, dates, range_field:, start_field:, end_field:, year_field: nil)
        ranges = DRI::Metadata::Transformations.transform_date_ranges(dates_key => dates)
        return solr_doc if ranges.blank?

        solr_doc[range_field] = ranges

        years = DRI::Metadata::Transformations.date_range_years(ranges)
        solr_doc[year_field] = years if year_field
        solr_doc[start_field] = years.min
        solr_doc[end_field] = years.max

        solr_doc
      end

      public

      load_inherited_terminology
    end
  end
end
