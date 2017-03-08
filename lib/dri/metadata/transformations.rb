# DRI namespace
module DRI
  # Metadata namespace
  module Metadata
    # Implements general, common methods, used in descMetadata classes for handling metadata transformations for
    # indexing
    module Transformations
      require 'iso8601'

      # The name of the Solr field for indexing temporal metadata (creation date)
      CREATION_DATE_RANGE_SOLR_FIELD = 'cdateRange'
      CREATION_DATE_YEAR_SOLR_FIELD = 'cdate_year_iim'
      CREATION_DATE_RANGE_START_SOLR_FIELD = 'cdate_range_start_isi'
      CREATION_DATE_RANGE_END_SOLR_FIELD = 'cdate_range_end_isi'
      # The name of the Solr field for indexing temporal metadata (published date)
      PUBLISHED_DATE_RANGE_SOLR_FIELD = 'pdateRange'
      PUBLISHED_DATE_YEAR_SOLR_FIELD = 'pdate_year_iim'
      PUBLISHED_DATE_RANGE_START_SOLR_FIELD = 'pdate_range_start_isi'
      PUBLISHED_DATE_RANGE_END_SOLR_FIELD = 'pdate_range_end_isi'
      # The name of the Solr field for indexing temporal metadata (date)
      DATE_RANGE_SOLR_FIELD = 'ddateRange'
      # The name of the Solr field for indexing temporal metadata (subject temporal)
      SUBJECT_DATE_RANGE_SOLR_FIELD = 'sdateRange'
      SUBJECT_DATE_RANGE_START_SOLR_FIELD = 'sdate_range_start_isi'
      SUBJECT_DATE_RANGE_END_SOLR_FIELD = 'sdate_range_end_isi'
      # The name of the Solr field for indexing geographical metadata
      GEOSPATIAL_SOLR_FIELD = 'geospatial'

      # The name of the Solr field for indexing coordinates geographical metadata (geojson index)
      # Solrizer only creates _tesim; for BL Maps we need _ssim
      GEOJSON_SOLR_FIELD = 'geojson_ssim'
      # The name of the Solr field for indexing placenames for geographical metadata (geojson index)
      PLACENAME_SOLR_FIELD = 'placename_field'

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
          name_parts = archived_name.split(',')

          firstname = ''
          surname = ''
          prefix = ''
          misc = ''

          if name_parts.length > 0
            surname_parts = name_parts[0].split('(')
            surname = surname_parts[0].strip
            misc += surname_parts[1..-1].join('(')
          end

          if name_parts.length > 1
            firstname_parts = name_parts[1].split('(')
            firstname = firstname_parts[0].strip
            misc += firstname_parts[1..-1].join('(')
          end

          if name_parts.length > 2
            prefix_parts = name_parts[2].split('(')
            prefix = prefix_parts[0].strip
            misc += prefix_parts[1..-1].join('(')
          end

          result = ''
          result += "#{firstname} " unless firstname.empty?

          unless prefix.empty?
            result += prefix
            result += ' ' unless prefix[-1, 1] == '-'
          end

          result += "#{surname} " unless surname.empty?

          result += misc unless misc.empty?

          result = result.strip

          results |= [result] unless result.empty?
        end

        results
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
      # @return [Array<String>] the array of formatted coordinates or bbox for indexing
      #
      def self.transform_geospatial(geodata = {})
        results = {}
        results[:coords] = []
        results[:name] = []
        results[:json] = []

        box_keys = %w(name eastlimit northlimit westlimit southlimit)
        point_keys = %w(name east north)

        geodata.each do |_key, value|
          value.each do |geo_string|
            if dcmi_point?(geo_string)
              begin
                point = get_geo_point(geo_string)
              rescue Exception => e
                Rails.logger.error("Exception in transform_geospatial: #{geo_string} => #{e}")
                break
              end
              # [east_long north_lat]
              if self.all_keys?(point_keys, point)
                results[:coords] << "#{point['east']} #{point['north']}"
                results[:name] << point['name']
                results[:json] << geojson_string_from_coords(point['name'], "#{point['east']} #{point['north']}")
              end
            elsif dcmi_box?(geo_string)
              begin
                box = get_geo_box(geo_string)
              rescue Exception => e
                Rails.logger.error("Exception in transform_geospatial: #{geo_string} => #{e}")
                break
              end
              # [west_long south_lat east_long north_lat]
              if self.all_keys?(box_keys, box)
                # Solr 5 changed format to ENVELOPE(minX, maxX, maxY, minY)
                results[:coords] << "ENVELOPE(#{box['westlimit']}, #{box['eastlimit']}, #{box['northlimit']}, #{box['southlimit']})"
                results[:name] << box['name']
                results[:json] << geojson_string_from_coords(box['name'], "#{box['westlimit']} #{box['southlimit']} #{box['eastlimit']} #{box['northlimit']}")
              end
            elsif geo_string =~ /\A#{URI.regexp(['http', 'https'])}\z/
              ld = DRI::LinkedData.where(source: geo_string)
              unless ld.empty?
                geojson = ld.first.spatial
                geojson.each do |geo|
                  geojson_hash = JSON.parse(geo, symbolize_names: true)
                  results[:json] << geo
                  results[:name] << geojson_hash[:properties][:placename]
                  results[:coords] << "#{geojson_hash[:geometry][:coordinates][0]} #{geojson_hash[:geometry][:coordinates][1]}"
                end
              end
            end
          end
        end

        results
      end

      # Parse geospatial data sourced from the metadata and transform into DCMI Point encoding
      #
      # @param [String] value the metadata coordinates string
      # @return [Array<String>] the transformed metadata coordinates formatter as DCMI Point into a Hash
      #
      def self.get_geo_point(value = nil)
        return {} if value.nil?

        point = {}

        value.split(/\s*;\s*/).each do |component|
          (k, v) = component.split(/\s*=\s*/)
          case k
          when 'east'
            point['east'] = v.strip
          when 'north'
            point['north'] = v.strip
          when 'name'
            point['name'] = v.strip
          end
        end

        point
      end

      # Parse geospatial data sourced from the metadata and transform into DCMI Box encoding
      #
      # @param [String] value the metadata coordinates string
      # @return [Hash] the transformed metadata coordinates formatter as DCMI Box into a Hash
      #
      def self.get_geo_box(value = nil)
        return {} if value.nil?

        box = {}

        value.split(/\s*;\s*/).each do |component|
          (k, v) = component.split(/\s*=\s*/)
          case k
          when 'northlimit'
            box['northlimit'] = v.strip
          when 'eastlimit'
            box['eastlimit'] = v.strip
          when 'southlimit'
            box['southlimit'] = v.strip
          when 'westlimit'
            box['westlimit'] = v.strip
          when 'name'
            box['name'] = v.strip
          end
        end

        box
      end

      #---------------------------------------------------------------------------------------------------------------
      # Date, Time transformations for indexing
      #---------------------------------------------------------------------------------------------------------------

      # Parse dates sourced from the metadata into properly formatted date ranges for indexing into Solr
      #
      # @param [Hash] dates hash containing all the dates values from the metadata
      # @option dates [Array] :start the array of start dates from metadata
      # @option dates [Array] :end the array of end dates from metadata
      # @return [String] the array of formatted dates strings for indexing (start_date end_date)
      #
      def self.transform_date_ranges(dates = {})
        results = []
        dates.each do |_key, value|
          value.each do |date_string|
            range = date_range(date_string)
            if range.key?('start') && range.key?('end')
              results << "[#{range['start']} TO #{range['end']}]"
            elsif range.key?('start')
              results << "#{range['start']}"
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
          endpoints = range.gsub(/\[(.*)\]/, '\1').split(/\sTO\s/)
          endpoints.each do |point|
            years << ISO8601::DateTime.new(point).year
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
         results[k.to_sym] = v unless v.nil? || v.empty?
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

      # Determines whether a date string is formatted according to DCMI Period
      #
      # @param [String] value the date string
      # @return [Boolean] true if DCMI Period formatted; false otherwise
      def self.dcmi_period?(value)
        result = false

        value.split(/\s*;\s*/).each do |component|
          (k, _v) = component.split(/\s*=\s*/)

          result = true if %w(start end scheme).include? k
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

          result = true if %w(east north elevation).include? k
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

          comps_array = %w(eastlimit northlimit southlimit westlimit uplimit downlimit)

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

      # Transforms a geocode into a Geo Json Hash
      # @param [String] name the displayable place name for a geocode value
      # @param [String] coords the string including the coordinates for a geocode value
      # @return [Hash] the hash including the geocode value formatted in GEO Json
      def self.geojson_string_from_coords(name, coords)
        geojson_hash = { type: 'Feature', geometry: {}, properties: {} }

        if coords.scan(/[\s]/).length == 3
          # bbox
          coords_array = coords.split(' ').map(&:to_f)
          geojson_hash[:bbox] = coords_array
          geojson_hash[:geometry][:type] = 'Polygon'
          geojson_hash[:geometry][:coordinates] = [[[coords_array[0], coords_array[1]],
                                                    [coords_array[2], coords_array[1]],
                                                    [coords_array[2], coords_array[3]],
                                                    [coords_array[0], coords_array[3]],
                                                    [coords_array[0], coords_array[1]]]]
        elsif coords.match(/^[-]?[\d]*[\.]?[\d]*[ ,][-]?[\d]*[\.]?[\d]*$/)
          # point
          geojson_hash[:geometry][:type] = 'Point'

          if coords.match(/,/)
            coords_array = coords.split(',').reverse
          else
            coords_array = coords.split(' ')
          end

          geojson_hash[:geometry][:coordinates] = coords_array.map(&:to_f)
        else
          Rails.logger.error("This coordinate format is not yet supported: '#{coords}'")
        end
        geojson_hash[:properties] = {}
        geojson_hash[:properties][:placename] = name

        # Return as a JSON String for blacklight-maps
        geojson_hash.to_json.to_s
      end

      # Transforms a geocode string encoded using DCMI Point or Box into a suitable formatted string of
      # coordinates for their indexing in the geographical indices.
      # E.g. Box: 'eastlimit, northlimit, westlimit, southlimit'
      #      Point: 'east north'
      # @param [String] geo_string the geocode string encoded in DCMI Point or Box
      # @return [String] the string containing the geocode coordinates suitable for geographic indexing
      def self.get_spatial_coordinates(geo_string)
        coordinates = ''

        if DRI::Metadata::Transformations.dcmi_point?(geo_string)
          lat = ''
          long = ''

          geo_string.split(/\s*;\s*/).each do |component|
            (k, v) = component.split(/\s*=\s*/)
            if k.eql?('east')
              lat = v.strip unless v.nil? || v.empty?
            elsif k.eql?('north')
              long = v.strip unless v.nil? || v.empty?
            end
          end

          coordinates = "#{lat} #{long}" unless lat.empty? || long.empty?
        elsif DRI::Metadata::Transformations.dcmi_box?(geo_string)
          eastlimit = ''
          northlimit = ''
          westlimit = ''
          southlimit = ''

          geo_string.split(/\s*;\s*/).each do |component|
            (k, v) = component.split(/\s*=\s*/)
            if k.eql?('eastlimit')
              eastlimit = v.strip unless v.nil? || v.empty?
            elsif k.eql?('northlimit')
              northlimit = v.strip unless v.nil? || v.empty?
            elsif k.eql?('westlimit')
              westlimit = v.strip unless v.nil? || v.empty?
            elsif k.eql?('southlimit')
              southlimit = v.strip unless v.nil? || v.empty?
            end
          end
          coords_array = [eastlimit, northlimit, westlimit, southlimit]
          coordinates = "#{westlimit} #{southlimit} #{eastlimit} #{northlimit}" if coords_array.all? { |coord| !coord.empty? }
        end

        coordinates
      end

      private

      def self.all_keys?(key_array = [], hash = {})
        key_array.all? { |s| hash.key? s }
      end
    end
  end
end
