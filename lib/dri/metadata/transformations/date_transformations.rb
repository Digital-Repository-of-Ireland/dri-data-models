# frozen_string_literal: true

module DRI::Metadata::Transformations
  # Parses and formats date/time metadata (DCMI Period and ISO8601 strings)
  # for Solr date-range indexing.
  module DateTransformations
    # Parse dates sourced from the metadata into properly formatted date ranges for indexing into Solr
    #
    # @param [Hash] dates hash containing all the dates values from the metadata
    # @option dates [Array] :start the array of start dates from metadata
    # @option dates [Array] :end the array of end dates from metadata
    # @return [Array<String>] the array of formatted dates strings for indexing [start_date TO end_date]
    def transform_date_ranges(dates = {})
      results = []

      dates.each_value do |values|
        values.each do |date_string|
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
    def date_range(value)
      return {} if value.nil?

      range = {}

      # DCMI Period?
      value.split(/\s*;\s*/).each do |component|
        k, v = component.split(/\s*=\s*/)
        next if v.nil?

        begin
          case k
          when 'start' then range['start'] = validated_iso8601(v)
          when 'end' then range['end'] = validated_iso8601(v)
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

    def date_range_years(ranges)
      years = []

      ranges.each do |range|
        endpoints = range.gsub(/\[|\]/, '').strip.split(/\sTO\s/)

        endpoints.each do |point|
          begin
            years << ISO8601::DateTime.new(point).year
          rescue ISO8601::Errors::StandardError
            next
          end
        end
      end

      years
    end

    # Transforms a date range string in ISO8601 (e.g. YYYYmmdd/YYYYmmdd) into a format
    # for indexing of date ranges into Solr
    # @param [String] val the date string
    # @return [Array<String>] the array containing start and end dates for date range indexing
    def transform_iso8601_range(val = '')
      if val.include?('/')
        val.split('/').map do |date|
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
          [val]
        rescue ISO8601::Errors::StandardError => e
          Rails.logger.error("Date #{val} not indexed as it is not compliant with ISO8601. Error: #{e}.")
          []
        end
      end
    end

    def transform_period(value)
      return {} if value.nil?

      DcmiParser.components(value).each_with_object({}) do |(k, v), results|
        results[k.to_sym] = v if v.present?
      end
    end

    # Determines whether a date string is formatted according to ISO8601
    #
    # @param [String] value the date string
    # @return [Boolean] true if ISO8601 formatted; false otherwise
    def iso8601?(value)
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

    def valid_range?(range)
      ISO8601::DateTime.new(range['start']).to_f < ISO8601::DateTime.new(range['end']).to_f
    end

    # Returns a DCMI Period formatted string
    #
    # @param [String] name the display name string for the date
    # @param [String] sdate the start date string
    # @param [String] edate the end date string
    # @param [String] scheme the encoding scheme for the date string, e.g. ISO8601
    # @return [String] the DCMI Period formatted string
    #
    def create_dcmi_period(name, sdate = '', edate = '', scheme = '')
      parts = [
        "name=#{name};",
        (sdate.present? ? "start=#{sdate};" : nil),
        (edate.present? ? "end=#{edate};" : nil),
        (scheme.present? ? "scheme=#{scheme};" : nil)
      ].compact

      parts.join(' ').rstrip
    end

    private

    def validated_iso8601(value)
      ISO8601::DateTime.new(value)
      value
    end
  end
end
