module DRI
 module Metadata
    # An ActiveFedora datastream that interacts with MARC-XML Metadata.
    class Marc < DRI::Metadata::Base
      extend DRI::Metadata::Terminologies::Marc

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

        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('date', :stored_searchable) => display_date_for_index(date))

        p_date = published_date
        if p_date
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('published_date', :stored_searchable) => display_date_for_index(p_date))

          pdate_ranges = DRI::Metadata::Transformations.transform_date_ranges({ 'published_date' => p_date })
          if pdate_ranges.present?
            solr_doc.merge!(DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_SOLR_FIELD => pdate_ranges)
            pdate_years = DRI::Metadata::Transformations.date_range_years(pdate_ranges)
            solr_doc.merge!(DRI::Metadata::Transformations::PUBLISHED_DATE_YEAR_SOLR_FIELD => pdate_years)
            solr_doc.merge!(DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_START_SOLR_FIELD => pdate_years.min)
            solr_doc.merge!(DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_END_SOLR_FIELD => pdate_years.max)
          end
        end

        ddate_ranges = DRI::Metadata::Transformations.transform_date_ranges({ 'date' => date })
        solr_doc.merge!(DRI::Metadata::Transformations::DATE_RANGE_SOLR_FIELD => ddate_ranges) unless ddate_ranges == []
        if ddate_ranges.present?
          solr_doc.merge!(DRI::Metadata::Transformations::DATE_RANGE_SOLR_FIELD => ddate_ranges)
          ddate_years = DRI::Metadata::Transformations.date_range_years(ddate_ranges).minmax
          solr_doc.merge!(DRI::Metadata::Transformations::DATE_RANGE_START_SOLR_FIELD => ddate_years[0])
          solr_doc.merge!(DRI::Metadata::Transformations::DATE_RANGE_END_SOLR_FIELD => ddate_years[1])
        end

        solr_doc
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
          begin
            next if value.nil? || value.empty?

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
      end

      def date_from_all_materials
        return [] if all_materials_dates.empty? || ['b','c','d','n'].include?(all_materials_dates[:type])

        type_of_date = all_materials_dates[:type]
        date1 = all_materials_dates[:date1]
        date2 = all_materials_dates[:date2]

        case type_of_date
        when 's'
          name = "s#{date1}"
          start_date = date1
          end_date = ''
        when 'e'
          year = date1
          month = date2.slice(0, 2)
          day = date2.slice(2, 2)

          name = "e#{year}#{month}#{day}"
          start_date = "#{year}#{month}#{day}"
          end_date = ''
        when 'p'
          name = "p#{date1}#{date2}"
          start_date = ''
          end_date = ''
        when 'm','i','k','q'
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
          start_date = "#{date1}"
          end_date = ''
        when 'd'
          name = "#{date1} - #{date2}"
          start_date = "#{date1}"
          end_date = "#{date2}"
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

        all_materials = controlfield[tag_index]
        type_of_date = all_materials[6]

        date1 = all_materials.slice(7,4)
        date2 = all_materials.slice(11,4)

        all_materials = {}
        all_materials[:type] = type_of_date
        all_materials[:date1] = date1
        all_materials[:date2] = date2

        all_materials
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
        date_result = false

        # Join all elements in array, get rid of carriage returns from the form (squish) and validate
        title_result = true unless title.join.squish.empty?
        type_result = true unless type.join.squish.empty?
        description_result = true unless description.join.squish.empty?
        creator_result = true unless creator.join.squish.empty?
        rights_result = true unless rights.join.squish.empty?
        date_result = true unless date.join.squish.empty?
        published_date.each { |curr_date| date_result = true unless curr_date.blank? } unless published_date.nil? || date_result

        title_result = true if title.any? { |v| !v.blank? }
        type_result = true if type.any? { |v| !v.blank? }
        description_result = true if description.any? { |v| !v.blank? }
        creator_result = true if creator.any? { |v| !v.blank? }
        rights_result = true if rights.any? { |v| !v.blank? }
        date_result = true if date.any? { |v| !v.blank? }

        errors[:title] = "can\'t be blank" if title_result == false
        errors[:type] = "can\'t be blank" if type_result == false
        errors[:description] = "can\'t be blank" if description_result == false
        errors[:creator] = "can\'t be blank" if creator_result == false
        errors[:date] = "can\'t be blank" if date_result == false
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

      load_inherited_terminology
    end
  end
end
