require 'dri/metadata/transformations/spatial_transformations'

# DRI namespace
module DRI
  # Metadata namespace
  module Metadata
    # Implements general, common methods, used in descMetadata classes for handling metadata transformations for
    # indexing
    module Transformations
      require 'iso8601'

      # The name of the Solr field for indexing temporal metadata (creation date)
      CREATION_DATE_RANGE_SOLR_FIELD = 'cdateRange'.freeze
      CREATION_DATE_YEAR_SOLR_FIELD = 'cdate_year_iim'.freeze
      CREATION_DATE_RANGE_START_SOLR_FIELD = 'cdate_range_start_isi'.freeze
      CREATION_DATE_RANGE_END_SOLR_FIELD = 'cdate_range_end_isi'.freeze
      # The name of the Solr field for indexing temporal metadata (published date)
      PUBLISHED_DATE_RANGE_SOLR_FIELD = 'pdateRange'.freeze
      PUBLISHED_DATE_YEAR_SOLR_FIELD = 'pdate_year_iim'.freeze
      PUBLISHED_DATE_RANGE_START_SOLR_FIELD = 'pdate_range_start_isi'.freeze
      PUBLISHED_DATE_RANGE_END_SOLR_FIELD = 'pdate_range_end_isi'.freeze
      # The name of the Solr field for indexing temporal metadata (date)
      DATE_RANGE_SOLR_FIELD = 'ddateRange'.freeze
      DATE_RANGE_START_SOLR_FIELD = 'date_range_start_isi'.freeze
      DATE_RANGE_END_SOLR_FIELD = 'date_range_end_isi'.freeze
      # The name of the Solr field for indexing temporal metadata (subject temporal)
      SUBJECT_DATE_RANGE_SOLR_FIELD = 'sdateRange'.freeze
      SUBJECT_DATE_RANGE_START_SOLR_FIELD = 'sdate_range_start_isi'.freeze
      SUBJECT_DATE_RANGE_END_SOLR_FIELD = 'sdate_range_end_isi'.freeze
      # The name of the Solr field for indexing geographical metadata
      GEOSPATIAL_SOLR_FIELD = 'geospatial'.freeze

      # The name of the Solr field for indexing coordinates geographical metadata (geojson index)
      # Solrizer only creates _tesim; for BL Maps we need _ssim
      GEOJSON_SOLR_FIELD = 'geojson_ssim'.freeze
      # The name of the Solr field for indexing placenames for geographical metadata (geojson index)
      PLACENAME_SOLR_FIELD = 'placename_field'.freeze

      # A function to convert an array of names that conform to archiving formatting
      # standards into human-readable names
      # so that a double-quotes search can pick up the full name
      # E.g. "Lewis, Daniel, Day-" is "Daniel Day-Lewis" and
      # "Valera, Eamon, de" is "Eamon de Valera"
      # @param [Array<String>] names the array of metadata people's names
      # @return [Array<String>] the array of transformed metadata people's names
      def self.transform_name(names = [])
        results = []

        names.each do |archived_name|
          archived_name = extract_name(CGI.unescapeHTML(archived_name))
          next if !person_name?(archived_name)

          name_parts = archived_name.strip.split(',')
          next if name_parts.empty?

          sorted_name = name_parts[0].strip + ", " + name_parts[1..-1].join(" ").strip
          parsed_name = Namae.parse(sorted_name)

          result = parsed_name[0].display_order unless parsed_name.empty?
          results |= [result] if result
        end

        results
      end

      def self.extract_name(name)
        name = name_from_orcid(name)
        name_remove_dates(name)
      end

      def self.name_from_orcid(name)
        return name unless name.start_with?('name=')
        name['name='.length..name.index(';')-1]
      end

      def self.name_remove_dates(name)
        name.gsub(/\(?\s*\d+\s*-\s*\d+\s*\)?/,'')
      end

      def self.person_name?(name)
        return false if name.include?("--") # lcsh style

        name = name.downcase
        !(%w(ltd ltd. limited archive museum archives library firm nui gallery services consultancy associates university).any? { |word| name.include?(word) })
      end

      # A function to convert a title string removing definite articles, unneccessary spaces, etc.
      #
      # @param [String] title_string the metadata title string
      # @return [String] the transformed metadata title string
      def self.transform_title_for_sort(title_string = '')
        # Space out non-word and non-number characters
        # and 'squeeze' the spaces
        title_string = title_string.gsub(/[^[:alnum:]]/, ' ').squeeze(' ')

        # Remove starting spaces
        title_string = title_string.strip

        # Remove leading definite articles
        title_string = title_string.gsub(/^(the|an|ná|na|a) /i, '')

        title_string
      end

      # Parse geospatial data sourced from the metadata into Point or BBox for indexing into Solr
      #
      # @param [Hash] geodata the hash containing all the geo values from the metadata
      # @return [Hash] parsed geospatial strings for indexing
      #
      def self.transform_geospatial(geodata = {})
        results = { coords: [], name: [], json: [] }

        geodata.each do |_key, value|
          value.each do |geo_string|
            result = if dcmi_point?(geo_string)
                       DRI::Metadata::Transformations::SpatialTransformations.parse_dcmi_point(geo_string)
                     elsif dcmi_box?(geo_string)
                       DRI::Metadata::Transformations::SpatialTransformations.parse_dcmi_box(geo_string)
                     elsif geo_string =~ /\A#{URI.regexp(['http', 'https'])}\z/
                       DRI::Metadata::Transformations::SpatialTransformations.from_url(geo_string)
                     else
                       { name: geo_string } #not a point or box so index string into placename solr field
                     end

            next if result.blank?

            results[:coords].push(result[:coords]) if result[:coords].present?
            results[:name].push(result[:name]) unless result[:name].nil?
            results[:json].push(result[:json]) if result[:json].present?
          end
        end

        results[:json] = filter_projections(results[:json])
        results
      end

      def self.filter_projections(geojson_strings)
        features = geojson_strings.map { |geojson_string| JSON.parse(geojson_string) }

        ['http://www.opengis.net/def/crs/EPSG/0/2157', 'http://www.opengis.net/def/crs/EPSG/0/29903'].each do |projection|
          filtered = features.select { |feature| feature['properties'].dig('geometryCRS', 'crs') == projection }
          return filtered.map { |feature| feature.to_json.to_s } if filtered.present?
        end

        features.map { |feature| feature.to_json.to_s }
      end

      #---------------------------------------------------------------------------------------------------------------
      # Date, Time transformations for indexing
      #---------------------------------------------------------------------------------------------------------------

      # Parse dates sourced from the metadata into properly formatted date ranges for indexing into Solr
      #
      # @param [Hash] dates hash containing all the dates values from the metadata
      # @option dates [Array] :start the array of start dates from metadata
      # @option dates [Array] :end the array of end dates from metadata
      # @return [String] the array of formatted dates strings for indexing [start_date TO end_date]
      #
      def self.transform_date_ranges(dates = {})
        results = []
        dates.each do |_key, value|
          value.each do |date_string|
            range = date_range(date_string)

            if range.key?('start') && range.key?('end')
              results << "[#{range['start']} TO #{range['end']}]" if valid_range?(range)
            elsif range.key?('start')
              results << range['start']
            end
          end
        end

        results
      end

      # Parse a date string into an appropriate format for indexing
      # It supports parsing of DCMI Point encoded string as well as ISO8601 string-encoded dates
      # If the date is not in a valid format it will be ignored
      # @param [String] value the date string
      # @return [Hash] hash containing start and date fields, with their values
      def self.date_range(value)
        return {} if value.nil?

        range = {}

        # DCMI Period?
        value.split(/\s*;\s*/).each do |component|
          (k, v) = component.split(/\s*=\s*/)
          next if v.nil?

          begin
            if k == 'start'
              ISO8601::DateTime.new(v)
              range['start'] = v
            elsif k == 'end'
              ISO8601::DateTime.new(v)
              range['end'] = v
            end
          rescue ISO8601::Errors::StandardError => e
            Rails.logger.error("Date #{v} not indexed as it is not compliant with ISO8601. Error: #{e}.")
            return {}
          end
        end

        if range.empty?
          # Is it a ISO8601 date range (start/end)?
          date_array = transform_iso8601_range(value)
          unless date_array.empty?
            range['start'] = date_array[0]
            range['end'] = date_array[1] if date_array.length > 1
          end
        end

        range
      end

      def self.date_range_years(ranges)
        years = []
        ranges.each do |range|
          endpoints = range.gsub(/\[|\]/, '').strip.split(/\sTO\s/)
          endpoints.each do |point|
            begin
              years << ISO8601::DateTime.new(point).year
            rescue ISO8601::Errors::StandardError
            end
          end
        end

        years
      end

      # Transforms a date range string in ISO8601 (e.g. YYYYmmdd/YYYYmmdd) into a format
      # for indexing of date ranges into Solr
      # @param [String] val the date string
      # @return [Array<String>] the array containing start and end dates for date range indexing
      def self.transform_iso8601_range(val = '')
        dates = []

        if val.include?('/')
          range = val.split('/')
          dates = range.collect!.each do |date|
            begin
              ISO8601::DateTime.new(date)
              date
            rescue ISO8601::Errors::StandardError => e
              Rails.logger.error("Date #{date} not indexed as it is not compliant with ISO8601. Error: #{e}.")
              return []
            end
          end
        else
          begin
            ISO8601::DateTime.new(val)
            dates[0] = val
          rescue ISO8601::Errors::StandardError => e
            Rails.logger.error("Date #{val} not indexed as it is not compliant with ISO8601. Error: #{e}.")
            return []
          end
        end

        dates
      end # transform_iso8601_range

      def self.transform_period(value)
        return {} if value.nil?

        results = {}
        value.split(/\s*;\s*/).each do |component|
         (k,v) = component.split(/\s*=\s*/)
         results[k.to_sym] = v if v.present?
        end

        results
      end

      # Determines whether a date string is formatted according to ISO8601
      #
      # @param [String] value the date string
      # @return [Boolean] true if ISO8601 formatted; false otherwise
      def self.iso8601?(value)
        begin
          if value.is_a?(Date) || value.is_a?(Time)
            ISO8601::DateTime.new(value.to_s)
          elsif !value.empty?
            ISO8601::DateTime.new(value)
          end

          true
        rescue ISO8601::Errors::StandardError => e
          Rails.logger.error("Unable to parse `#{value}' as a date-time object. Error: #{e}.")

          false
        end
      end

      def self.valid_range?(range)
        start_date = range['start']
        end_date = range['end']

        ISO8601::DateTime.new(start_date).to_f < ISO8601::DateTime.new(end_date).to_f
      end

      # Determines whether a date string is formatted according to DCMI Period
      #
      # @param [String] value the date string
      # @return [Boolean] true if DCMI Period formatted; false otherwise
      def self.dcmi_period?(value)
        result = false

        value.split(/\s*;\s*/).each do |component|
          (k, _v) = component.split(/\s*=\s*/)

          result = true if %w[start end scheme].include? k
        end

        result
      end

      # Determines whether a geocode string is formatted according to DCMI Point
      #
      # @param [String] value the geocode string
      # @return [Boolean] true if DCMI Point formatted; false otherwise
      def self.dcmi_point?(value)
        result = false

        value.split(/\s*;\s*/).each do |component|
          (k, _v) = component.split(/\s*=\s*/)

          result = true if %w[east north elevation projection].include? k
        end

        result
      end

      # Determines whether a geocode string is formatted according to DCMI Box
      #
      # @param [String] value the geocode string
      # @return [Boolean] true if DCMI Box formatted; false otherwise
      def self.dcmi_box?(value)
        result = false

        value.split(/\s*;\s*/).each do |component|
          (k, _v) = component.split(/\s*=\s*/)

          comps_array = %w[eastlimit northlimit southlimit westlimit uplimit downlimit]

          result = true if comps_array.include? k
        end

        result
      end

      # Determines whether a string is encoded using DCMI Box, Point or Period
      # @param [String] value the string to check
      # @return [Boolean] true if DCMI Box, Point or Period encoded; false otherwise
      def self.dcmi_encoded?(value)
        dcmi_box?(value) || dcmi_period?(value) || dcmi_point?(value)
      end

      # Returns a DCMI Period formatted string
      #
      # @param [String] name the display name string for the date
      # @param [String] sdate the start date string
      # @param [String] edate the end date string
      # @param [String] scheme the encoding scheme for the date string, e.g. ISO8601
      # @return [String] the DCMI Period formatted string
      def self.create_dcmi_period(name, sdate = '', edate = '', scheme = '')
        name_comp = "name=#{name};"
        sdate_comp = "#{sdate != '' ? 'start=' << sdate << ';' : ''}"
        edate_comp = "#{edate != '' ? 'end=' << edate << ';' : ''}"
        scheme_comp = "#{scheme != '' ? 'scheme=' << scheme << ';' : ''}"

        "#{name_comp} #{sdate_comp} #{edate_comp} #{scheme_comp}".rstrip
      end

      # Transforms a geocode string encoded using DCMI Point or Box into a suitable formatted string of
      # coordinates for their indexing in the geographical indices.
      # E.g. Box: 'eastlimit, northlimit, westlimit, southlimit'
      #      Point: 'east north'
      # @param [String] geo_string the geocode string encoded in DCMI Point or Box
      # @return [String] the string containing the geocode coordinates suitable for geographic indexing
      def self.get_spatial_coordinates(geo_string)
        coordinates = ''

        if dcmi_point?(geo_string)
          lat = ''
          long = ''

          geo_string.split(/\s*;\s*/).each do |component|
            (k, v) = component.split(/\s*=\s*/)
            if k == 'east'
              lat = v.strip if v.present?
            elsif k == 'north'
              long = v.strip if v.present?
            end
          end

          coordinates = "#{lat} #{long}" unless lat.empty? || long.empty?
        elsif dcmi_box?(geo_string)
          eastlimit = ''
          northlimit = ''
          westlimit = ''
          southlimit = ''

          geo_string.split(/\s*;\s*/).each do |component|
            (k, v) = component.split(/\s*=\s*/)
            if k == 'eastlimit'
              eastlimit = v.strip if v.present?
            elsif k == 'northlimit'
              northlimit = v.strip if v.present?
            elsif k == 'westlimit'
              westlimit = v.strip if v.present?
            elsif k == 'southlimit'
              southlimit = v.strip if v.present?
            end
          end
          coords_array = [eastlimit, northlimit, westlimit, southlimit]
          coordinates = "#{westlimit} #{southlimit} #{eastlimit} #{northlimit}" if coords_array.all? { |coord| !coord.empty? }
        end

        coordinates
      end
    end
  end
end
