module DRI
  module Metadata
    # A datastream that interacts with Qualified DC Metadata.
    class QualifiedDublinCore < DRI::Datastreams::OmDatastream
      include DRI::Metadata
      extend DRI::Metadata::Terminologies::Qdc

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
        recognised_attributes = [:title, :rights, :description, :language, :subject, :subject_lang, :date, :contributor,
                                 :source, :publisher, :coverage, :coverage_lang, :relation, :creator, :format, :type,
                                 :identifier, :published_date, :creation_date, :geographical_coverage, :geographical_coverage_lang,
                                 :temporal_coverage, :temporal_coverage_lang, :geocode_point, :geocode_box]
        if recognised_attributes.include? field
          [field]
        elsif
          m = /^role_(.*)/.match(field.to_s)
          DRI::Vocabulary.marc_relators.include?(m[1]) ? [field] : []
        else
          []
        end
      end

      # Override from OmDatastream. Update Solr indexed attributes based on metadata
      # @param [Hash] params the hash of attributes to update
      # @param [Hash] opts the hash of custom options
      def update_indexed_attributes(params = {}, opts = {})
        # if the params are just keys, not an array, make then into an array.
        new_params = {}
        params.each do |key, val|
          if key.is_a? Array
            new_params[key] = val
          else
            new_params[[key.to_sym]] = val
          end
        end

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
          unless roles['name'][i].empty?
            changed_roles[role].push(roles['name'][i])
          end
        end
        
        %w(contributor publisher).each do |role|
          value = changed_roles.key?(role) ? changed_roles[role] : []
          send("#{role}=", value)
        end

        DRI::Vocabulary.marc_relators.map do |s|
          role = s.prepend('role_')
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
                          'xsi:noNamespaceSchemaLocation' => 'http://dublincore.org/schemas/xmls/qdc/2008/02/11/qualifieddc.xsd') {
            xml['dc'].title
            xml['dc'].description
          }
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

        # Index dates here, for display
        solr_doc['creation_date_tesim'] = display_date_for_index(creation_date)
        solr_doc['published_date_tesim'] = display_date_for_index(published_date)

        temporal_coverage_dates = display_date_for_index(temporal_coverage)
        if temporal_coverage_dates.present?
          solr_doc['temporal_coverage_tesim'] = temporal_coverage_dates
          solr_doc['temporal_coverage_sim'] = filter_uris(temporal_coverage_dates)
        end

        solr_doc['geographical_coverage_sim'] = filter_uris(geographical_coverage)

        solr_doc['date_tesim'] = display_date_for_index(date)

        solr_doc = remove_null_values(solr_doc, 'creation_date') if solr_doc['creation_date_tesim'].present?
        solr_doc = remove_null_values(solr_doc, 'published_date') if solr_doc['published_date_tesim'].present?
        solr_doc = remove_null_values(solr_doc, 'date') if solr_doc['date_tesim'].present?
        solr_doc = remove_null_values(solr_doc, 'temporal_coverage') if solr_doc['temporal_coverage_tesim'].present?
        solr_doc = remove_null_values(solr_doc, 'creator') if solr_doc['creator_tesim'].present?

        # Retrieve list of all people and add them to facet and search indexes in solr document
        solr_doc['person_sim'] = person_array
        solr_doc['person_tesim'] = person_array | DRI::Metadata::Transformations.transform_name(person_array)

        # title_sorted - A SOLR index for sorting titles
        if title.length > 0
          sorted_title = DRI::Metadata::Transformations.transform_title_for_sort(title[0])
          unless sorted_title.empty?
            solr_doc['title_sorted_ssi'] = [sorted_title]
          end
        end

       # all_metadata - A SOLR index of all the text contained in the XML document
        all_metadata = ''
        ng_xml.xpath('//text()').each do |text_node|
          all_metadata += text_node.text
          all_metadata += ' '
        end
        solr_doc['all_metadata_tesim'] = [all_metadata]

        # Split facets into different languages based on xml:lang
        faceted_language_indexes = {}
        faceted_language_indexes.merge! split_array_into_languages('title')
        faceted_language_indexes.merge! split_array_into_languages('rights')
        faceted_language_indexes.merge! split_array_into_languages('subject')
        faceted_language_indexes.merge! split_array_into_languages('coverage')
        faceted_language_indexes.merge! split_array_into_languages('temporal_coverage')
        faceted_language_indexes.merge! split_array_into_languages('geographical_coverage')
        faceted_language_indexes.merge! split_array_into_languages('source')
        faceted_language_indexes.merge! split_array_into_languages('name_coverage')

        faceted_language_indexes.each do |key, value|
          solr_doc["#{key}_tesim"] = value
          solr_doc["#{key}_sim"] = filter_uris(value)
        end

        split_array_into_languages('description').each do |key, value|
          solr_doc["#{key}_tesim"] = value
        end

        # Indices for external relationships (to be displayed as URL)
        external_rels = *(DRI::Vocabulary.qdc_relationship_types.map { |s| s.prepend('ext_related_items_ids_').to_sym })

        external_rels.each do |elem|
          solr_doc["#{elem}_tesim"] = send(elem) unless send(elem) == []
        end

        # dateRangeField is defined in Solr's schema.xml as a field of type date_range (solr.SpatialRecursivePrefixTreeFieldType)
        cdate_ranges = DRI::Metadata::Transformations.transform_date_ranges({ 'creation_date' => creation_date })
        pdate_ranges = DRI::Metadata::Transformations.transform_date_ranges({ 'published_date' => published_date })
        ddate_ranges = DRI::Metadata::Transformations.transform_date_ranges({ 'date' => date })
        sdate_ranges = DRI::Metadata::Transformations.transform_date_ranges({ 'temporal_coverage' => temporal_coverage })

        if cdate_ranges.present?
          solr_doc[DRI::Metadata::Transformations::CREATION_DATE_RANGE_SOLR_FIELD] = cdate_ranges
          cdate_years = DRI::Metadata::Transformations.date_range_years(cdate_ranges)
          solr_doc[DRI::Metadata::Transformations::CREATION_DATE_YEAR_SOLR_FIELD] = cdate_years
          solr_doc[DRI::Metadata::Transformations::CREATION_DATE_RANGE_START_SOLR_FIELD] = cdate_years.min
          solr_doc[DRI::Metadata::Transformations::CREATION_DATE_RANGE_END_SOLR_FIELD] = cdate_years.max
        end

        if pdate_ranges.present?
          solr_doc[DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_SOLR_FIELD] = pdate_ranges
          pdate_years = DRI::Metadata::Transformations.date_range_years(pdate_ranges)
          solr_doc[DRI::Metadata::Transformations::PUBLISHED_DATE_YEAR_SOLR_FIELD] = pdate_years
          solr_doc[DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_START_SOLR_FIELD] = pdate_years.min
          solr_doc[DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_END_SOLR_FIELD] = pdate_years.max
        end

        if sdate_ranges.present?
          solr_doc[DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_SOLR_FIELD] = sdate_ranges
          sdate_years = DRI::Metadata::Transformations.date_range_years(sdate_ranges).minmax
          solr_doc[DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_START_SOLR_FIELD] = sdate_years[0]
          solr_doc[DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_END_SOLR_FIELD] = sdate_years[1]
        end

        if ddate_ranges.present?
          solr_doc[DRI::Metadata::Transformations::DATE_RANGE_SOLR_FIELD] = ddate_ranges
          ddate_years = DRI::Metadata::Transformations.date_range_years(ddate_ranges).minmax
          solr_doc[DRI::Metadata::Transformations::DATE_RANGE_START_SOLR_FIELD] = ddate_years[0]
          solr_doc[DRI::Metadata::Transformations::DATE_RANGE_END_SOLR_FIELD] = ddate_years[1]
        end

        # Index dcterms Point and Box data, and linked data uris into geospatial Solr field
        geospatial_hash = DRI::Metadata::Transformations.transform_geospatial(
          {
            'geographical_coverage' => geographical_coverage | reconciliation_uris,
            'coverage' => coverage
          }
        )
        solr_doc[DRI::Metadata::Transformations::GEOSPATIAL_SOLR_FIELD] = geospatial_hash[:coords] if geospatial_hash[:coords].present?

        if geospatial_hash[:name].present?
          solr_doc["#{DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD}_tesim"] = geospatial_hash[:name]
          solr_doc["#{DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD}_sim"] = geospatial_hash[:name]
        end

        if geospatial_hash[:json].present?
          solr_doc[DRI::Metadata::Transformations::GEOJSON_SOLR_FIELD] = geospatial_hash[:json]
        end

        solr_doc
      end

      # Transforms metadata date strings into DCMI Period encoded strings for displayable indices
      # @param [String] date_field the date string
      # @return [String] the DCMI Period encoded date string for display
      def display_date_for_index(date_field)
        date_field = date_field.delete_if { |v| /^null$/i.match(v) }
        date_field.collect do |value|
          begin
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
      end

      # Some indexes may need to be split up into different languages
      # @param [String] index_name the name of the index field to split by language
      # @return [Hash] the hash with indices split by language
      def split_array_into_languages(index_name = '')
        results = {}

        return results if index_name.empty?

        array_values = send(index_name)
        # Remove empty tags from metadata: e.g. <dc:subject/>
        array_values = array_values.reject(&:empty?)

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

          if results.key?("#{index_name}_#{lang_code}")
            results["#{index_name}_#{lang_code}"] |= [value]
          else
            results["#{index_name}_#{lang_code}"] = [value]
          end
        end

        results
      end

      # Returns all metadata related to people names for Solr indexing
      # People facet
      # @return [Array<String>] array of all people names metadata values for Solr indexing
      def person_array
        people = contributor | publisher
        people |= creator.reject { |c| /^null$/i.match(c) }
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

        uri_result = false
        title_result = false
        description_result = false
        rights_result = false
        type_result = false
        date_result = false
        creator_result = false

        title.each { |curr_title| title_result = true if curr_title.present? }
        creator.each { |cre| creator_result = true if cre.present? }

        unless creator_result == true
          marc_rels = *(DRI::Vocabulary.marc_relators.map { |s| s.prepend('role_').to_sym })
          marc_rels.each do |role|
            send(role).each do |v|
              creator_result = true if v.present?
              break if creator_result == true
            end
            break if creator_result == true
          end
        end

        description.each { |curr_description| description_result = true if curr_description.present? }
        rights.each { |curr_right| rights_result = true if curr_right.present? }
        resource_type.each { |curr_type| type_result = true if curr_type.present? }

        date.each { |curr_date| date_result = true if curr_date.present? }
        creation_date.each { |curr_date| date_result = true if curr_date.present? } unless date_result
        published_date.each { |curr_date| date_result = true if curr_date.present? } unless date_result

        # Check that for external relationships terms, the specified URIs are valid
        external_relation.each { |uri_r| uri_result = true if uri_r.present? && Utils.valid_uri?(uri_r) }

        errors[:title] = "can\'t be blank" if title_result == false
        errors[:creator] = "can\'t be blank" if creator_result == false
        errors[:description] = "can\'t be blank" if description_result == false
        errors[:external_relation] = 'includes invalid URI' if external_relation.size.positive? && uri_result == false
        errors[:rights] = "can\'t be blank" if rights_result == false
        errors[:type] = "can\'t be blank" if type_result == false
        errors[:date] = "can\'t be blank" if date_result == false

        errors
      end

      # Load Dublin Core terminology
      load_inherited_terminology
    end
  end
end
