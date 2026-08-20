module DRI
  module Metadata
    # A datastream that interacts with Qualified DC Metadata.
    class QualifiedDublinCore < DRI::Datastreams::OmDatastream
      include DRI::Metadata
      extend DRI::Metadata::Terminologies::Qdc

      RECOGNISED_METADATA_PATH_ATTRIBUTES = %i[
        title rights access_rights description language subject subject_lang date contributor
        source publisher coverage coverage_lang relation creator format type
        identifier published_date creation_date geographical_coverage geographical_coverage_lang
        temporal_coverage temporal_coverage_lang geocode_point geocode_box
      ].freeze

      LANGUAGE_FACETED_FIELDS = %w[
        title rights access_rights subject coverage temporal_coverage
        geographical_coverage source name_coverage
      ].freeze

      # synchronize_metadata_on_save attribute getter
      # For non-EAD digital objects this is always false (disable)
      # @return [Boolean] true if object support children metadata objects creation; false otherwise
      def synchronize_metadata_on_save
        # Default to false as QDC object
        false
      end

      # Override from DRI::Metadata::Base.
      # Returns an array with the values of a metadata field if present as an object's attribute
      # @param [String] field the name of the metadata field
      # @return [Array<String>] the array of field metadata values
      def metadata_path(field)
        return [field] if RECOGNISED_METADATA_PATH_ATTRIBUTES.include?(field)

        match = /^role_(.*)/.match(field.to_s)
        return [] unless match

        DRI::Vocabulary.marc_relators.include?(match[1]) ? [field] : []
      end

      # Override from OmDatastream. Update Solr indexed attributes based on metadata
      # @param [Hash] params the hash of attributes to update
      # @param [Hash] opts the hash of custom options
      def update_indexed_attributes(params = {}, opts = {})
        # if the params are just keys, not an array, make then into an array.
        new_params = params.transform_keys { |key| key.is_a?(Array) ? key : [key.to_sym] }

        super(new_params, opts)
      end

      # Roles attribute setter
      # @example Sample Hash:
      #   { 'name' => ['Test host', 'new producer'],
      #     'type' => ['role_hst', 'role_pro']
      #   }
      # @param [Hash] roles hash with metadata marcrelator values
      # @option roles [Array<String>] :name the metadata values for the marcrelators in :type
      # @option roles [Array<String>] :type the marcrelator codes
      def roles=(roles)
        return unless roles.is_a?(Hash)
        return unless roles.key?('type') && roles.key?('name') && (roles['type'].size == roles['name'].size)

        changed_roles = {}
        roles['type'].uniq.each { |role| changed_roles[role] = [] }

        roles['type'].each_with_index do |role, i|
          changed_roles[role].push(roles['name'][i]) unless roles['name'][i].empty?
        end

        %w[contributor publisher].each do |role|
          value = changed_roles.key?(role) ? changed_roles[role] : []
          send("#{role}=", value)
        end

        DRI::Vocabulary.marc_relators.each do |relator|
          role = "role_#{relator}"
          value = changed_roles.key?(role) ? changed_roles[role] : []
          send("#{role}=", value)
        end
      end

      # Returns an empty, default QDC XML template
      #
      # @return [Nokogiri::Document] the QDC XML document
      def self.xml_template
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.qualifieddc('xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
                          'xmlns:dcterms' => 'http://purl.org/dc/terms/',
                          'xmlns:marcrel' => 'http://www.loc.gov/marc.relators/',
                          'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                          'xsi:schemaLocation' => 'http://www.loc.gov/marc.relators/ http://imlsdcc2.grainger.illinois.edu/registry/marcrel.xsd',
                          'xsi:noNamespaceSchemaLocation' => 'http://dublincore.org/schemas/xmls/qdc/2008/02/11/qualifieddc.xsd') do
            xml['dc'].title
            xml['dc'].description
          end
        end

        builder.doc
      end

      # Override from AF Solrizer for datastreams.
      # merge in special facets (e.g. person) into solr document
      # Update solr_doc Hash for index into Solr from the metadata
      # @param [Hash] solr_doc the solr document hash
      # @param [Hash] opts additional custom options
      # @return [Hash] the updated solr_doc hash for Solr index
      def to_solr(solr_doc = {}, opts = {})
        solr_doc = super(solr_doc, opts)

        solr_doc = index_dates_for_display!(solr_doc)
        solr_doc = strip_null_date_and_creator_values!(solr_doc)
        solr_doc = index_person!(solr_doc)
        solr_doc = index_title_sorted!(solr_doc)
        solr_doc = index_all_metadata!(solr_doc)
        solr_doc = index_language_facets!(solr_doc)
        solr_doc = index_external_relationships!(solr_doc)
        solr_doc = index_date_ranges!(solr_doc)
        solr_doc = index_geospatial!(solr_doc)

        solr_doc
      end

      # Transforms metadata date strings into DCMI Period encoded strings for displayable indices
      # @param [String] date_field the date string
      # @return [String] the DCMI Period encoded date string for display
      def display_date_for_index(date_field)
        date_field = date_field.reject { |v| /^null$/i.match?(v) }

        date_field.collect do |value|
          if value.empty? || DRI::Metadata::Transformations.dcmi_period?(value) || Utils.valid_uri?(value)
            # return value for display as it is
            # If value.empty? is cleaned afterwards
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

      # Some indexes may need to be split up into different languages
      # @param [String] index_name the name of the index field to split by language
      # @return [Hash] the hash with indices split by language
      def split_array_into_languages(index_name = '')
        results = {}

        return results if index_name.empty?

        # Remove empty tags from metadata: e.g. <dc:subject/>
        array_values = send(index_name).reject(&:empty?)

        array_values.each_with_index do |value, i|
          if index_name == 'temporal_coverage' && DRI::Metadata::Transformations.dcmi_period?(value)
            period = DRI::Metadata::Transformations.transform_period(value)
            next if period[:name].blank?

            value = period[:name]
          elsif index_name == 'geographical_coverage' && DRI::Metadata::Transformations.dcmi_encoded?(value)
            next
          end

          value_lang = send(index_name, i).send("#{index_name}_lang")
          lang_code = value_lang.length.positive? ? value_lang[0].strip : 'eng'
          lang_code = DRI::Metadata::Descriptors.standardise_language_code(lang_code) || 'eng'

          key = "#{index_name}_#{lang_code}"
          results[key] = (results[key] || []) | [value]
        end

        results
      end

      # Returns all metadata related to people names for Solr indexing
      # People facet
      # @return [Array<String>] array of all people names metadata values for Solr indexing
      def person_array
        people = contributor | publisher
        people |= creator.reject { |c| /^null$/i.match?(c) }
        DRI::Vocabulary.marc_relators.each { |role| people |= send("role_#{role}") }

        people
      end

      # Determine whether the metadata describes a collection
      def collection?
        resource_type.include? 'Collection'
      end

      # Implement additional DRI metadata validations as this class does not inherit
      # from DRI::Metadata::Base
      # @return [Hash] the hash with any errors from validation
      def custom_validations
        errors = {}

        errors[:title] = "can't be blank" unless metadata_present?(title)
        errors[:creator] = "can't be blank" unless creator_present?
        errors[:description] = "can't be blank" unless metadata_present?(description)
        errors[:external_relation] = 'includes invalid URI' if external_relation.present? && !valid_external_relations?
        errors[:rights] = "can't be blank" unless metadata_present?(rights)
        errors[:type] = "can't be blank" unless metadata_present?(resource_type)
        errors[:date] = "can't be blank" unless date_present?

        errors
      end

      private

      def metadata_present?(values)
        values.any?(&:present?)
      end

      def creator_present?
        return true if metadata_present?(creator)

        marc_role_fields.any? { |role_field| metadata_present?(send(role_field)) }
      end

      def date_present?
        metadata_present?(date) || metadata_present?(creation_date) || metadata_present?(published_date)
      end

      def valid_external_relations?
        external_relation.any? { |uri| uri.present? && Utils.valid_uri?(uri) }
      end

      def marc_role_fields
        DRI::Vocabulary.marc_relators.map { |role| :"role_#{role}" }
      end

      def index_dates_for_display!(solr_doc)
        solr_doc['creation_date_tesim'] = display_date_for_index(creation_date)
        solr_doc['published_date_tesim'] = display_date_for_index(published_date)

        temporal_coverage_dates = display_date_for_index(temporal_coverage)
        if temporal_coverage_dates.present?
          solr_doc['temporal_coverage_tesim'] = temporal_coverage_dates
          solr_doc['temporal_coverage_sim'] = filter_uris(temporal_coverage_dates)
        end

        solr_doc['geographical_coverage_sim'] = filter_uris(geographical_coverage)
        solr_doc['date_tesim'] = display_date_for_index(date)

        solr_doc
      end

      def strip_null_date_and_creator_values!(solr_doc)
        solr_doc = remove_null_values(solr_doc, 'creation_date') if solr_doc['creation_date_tesim'].present?
        solr_doc = remove_null_values(solr_doc, 'published_date') if solr_doc['published_date_tesim'].present?
        solr_doc = remove_null_values(solr_doc, 'date') if solr_doc['date_tesim'].present?
        solr_doc = remove_null_values(solr_doc, 'temporal_coverage') if solr_doc['temporal_coverage_tesim'].present?
        solr_doc = remove_null_values(solr_doc, 'creator') if solr_doc['creator_tesim'].present?
        solr_doc
      end

      # Retrieve list of all people and add them to facet and search indexes in solr document
      def index_person!(solr_doc)
        people = person_array

        solr_doc['person_sim'] = people
        solr_doc['person_tesim'] = people | DRI::Metadata::Transformations.transform_name(people)

        solr_doc
      end

      # title_sorted - A SOLR index for sorting titles
      def index_title_sorted!(solr_doc)
        return solr_doc if title.empty?

        sorted_title = DRI::Metadata::Transformations.transform_title_for_sort(title[0])
        solr_doc['title_sorted_ssi'] = [sorted_title] unless sorted_title.empty?

        solr_doc
      end

      # all_metadata - A SOLR index of all the text contained in the XML document
      def index_all_metadata!(solr_doc)
        solr_doc['all_metadata_tesim'] = [all_metadata_text]
        solr_doc
      end

      def all_metadata_text
        ng_xml.xpath('//text()').each_with_object('') { |node, str| str << node.text << ' ' }
      end

      # Split facets into different languages based on xml:lang
      def index_language_facets!(solr_doc)
        faceted_language_indexes = LANGUAGE_FACETED_FIELDS.each_with_object({}) do |field, acc|
          acc.merge!(split_array_into_languages(field))
        end

        faceted_language_indexes.each do |key, value|
          solr_doc["#{key}_tesim"] = value
          solr_doc["#{key}_sim"] = filter_uris(value)
        end

        split_array_into_languages('description').each do |key, value|
          solr_doc["#{key}_tesim"] = value
        end

        solr_doc
      end

      # Indices for external relationships (to be displayed as URL)
      def index_external_relationships!(solr_doc)
        external_rels = DRI::Vocabulary.qdc_relationship_types.map { |s| :"ext_related_items_ids_#{s}" }

        external_rels.each do |elem|
          values = send(elem)
          solr_doc["#{elem}_tesim"] = values unless values == []
        end

        solr_doc
      end

      # dateRangeField is defined in Solr's schema.xml as a field of type date_range (solr.SpatialRecursivePrefixTreeFieldType)
      def index_date_ranges!(solr_doc)
        cdate_ranges = DRI::Metadata::Transformations.transform_date_ranges('creation_date' => creation_date)
        pdate_ranges = DRI::Metadata::Transformations.transform_date_ranges('published_date' => published_date)
        ddate_ranges = DRI::Metadata::Transformations.transform_date_ranges('date' => date)
        sdate_ranges = DRI::Metadata::Transformations.transform_date_ranges('temporal_coverage' => temporal_coverage)

        index_date_range!(solr_doc, cdate_ranges,
                           range_field: DRI::Metadata::Transformations::CREATION_DATE_RANGE_SOLR_FIELD,
                           year_field: DRI::Metadata::Transformations::CREATION_DATE_YEAR_SOLR_FIELD,
                           start_field: DRI::Metadata::Transformations::CREATION_DATE_RANGE_START_SOLR_FIELD,
                           end_field: DRI::Metadata::Transformations::CREATION_DATE_RANGE_END_SOLR_FIELD)

        index_date_range!(solr_doc, pdate_ranges,
                           range_field: DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_SOLR_FIELD,
                           year_field: DRI::Metadata::Transformations::PUBLISHED_DATE_YEAR_SOLR_FIELD,
                           start_field: DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_START_SOLR_FIELD,
                           end_field: DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_END_SOLR_FIELD)

        index_date_range!(solr_doc, sdate_ranges,
                           range_field: DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_SOLR_FIELD,
                           start_field: DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_START_SOLR_FIELD,
                           end_field: DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_END_SOLR_FIELD)

        index_date_range!(solr_doc, ddate_ranges,
                           range_field: DRI::Metadata::Transformations::DATE_RANGE_SOLR_FIELD,
                           start_field: DRI::Metadata::Transformations::DATE_RANGE_START_SOLR_FIELD,
                           end_field: DRI::Metadata::Transformations::DATE_RANGE_END_SOLR_FIELD)

        solr_doc
      end

      # Shared by all four date-range blocks in index_date_ranges!, which
      # previously duplicated this range/year/min/max logic almost verbatim
      # (with creation_date/published_date storing a year array, and
      # temporal_coverage/date not). year_field is optional to account for
      # that difference.
      def index_date_range!(solr_doc, ranges, range_field:, start_field:, end_field:, year_field: nil)
        return solr_doc if ranges.blank?

        solr_doc[range_field] = ranges

        years = DRI::Metadata::Transformations.date_range_years(ranges)
        solr_doc[year_field] = years if year_field
        solr_doc[start_field] = years.min
        solr_doc[end_field] = years.max

        solr_doc
      end

      # Index dcterms Point and Box data, and linked data uris into geospatial Solr field
      def index_geospatial!(solr_doc)
        geospatial_hash = DRI::Metadata::Transformations.transform_geospatial(
          'geographical_coverage' => geographical_coverage | reconciliation_uris,
          'coverage' => coverage
        )

        solr_doc[DRI::Metadata::Transformations::GEOSPATIAL_SOLR_FIELD] = geospatial_hash[:coords] if geospatial_hash[:coords].present?

        if geospatial_hash[:name].present?
          solr_doc["#{DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD}_tesim"] = geospatial_hash[:name]
          solr_doc["#{DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD}_sim"] = geospatial_hash[:name]
        end

        solr_doc[DRI::Metadata::Transformations::GEOJSON_SOLR_FIELD] = geospatial_hash[:json] if geospatial_hash[:json].present?

        solr_doc
      end

      # Load Dublin Core terminology
      load_inherited_terminology
    end
  end
end
