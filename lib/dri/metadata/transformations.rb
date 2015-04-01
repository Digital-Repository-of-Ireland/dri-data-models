module DRI
  module Metadata
    module Transformations
      #require 'chronic'
      require 'iso8601'

      CREATION_DATE_RANGE_SOLR_FIELD = "cdateRange"
      PUBLISHED_DATE_RANGE_SOLR_FIELD = "pdateRange"
      SUBJECT_DATE_RANGE_SOLR_FIELD = "sdateRange"

	    # A function to convert an array of names that conform to archiving formatting standards into human-readable names
      # so that a double-quotes search can pick up the full name eg. "Lewis, Daniel, Day-" is "Daniel Day-Lewis" and
      # "Valera, Éamon, de" is "Éamon de Valera"
      def self.transform_name(names=Array.new)
        results = []

        names.each do |archived_name|
          name_parts = archived_name.split(",")

          firstname = ""
          surname = ""
          prefix = ""
          misc = ""

          if (name_parts.length > 0)
            surname_parts = name_parts[0].split("(")
            surname = surname_parts[0].strip
            misc += surname_parts[1..-1].join("(")
          end

          if (name_parts.length > 1)
            firstname_parts = name_parts[1].split("(")
            firstname = firstname_parts[0].strip
            misc += firstname_parts[1..-1].join("(")
          end

          if (name_parts.length > 2)
            prefix_parts = name_parts[2].split("(")
            prefix = prefix_parts[0].strip
            misc += prefix_parts[1..-1].join("(")
          end

          result = ""

          unless (firstname == "")
            result += firstname+" "
          end

          unless (prefix == "")
            result += prefix

            unless prefix[-1,1] == "-"
              result += " "
            end
          end

          unless (surname == "")
            result += surname+" "
          end

          unless (misc == "")
            result += misc
          end

          result = result.strip

          unless (result == "")
            results |= [result]
          end
        end

        return results
      end

      def self.transform_title_for_sort(title_string="")

        # Space out non-word and non-number characters and 'squeeze' the spaces
        title_string = title_string.gsub(/[[:^alnum:]]/, " ").squeeze(" ")

        # Remove starting spaces
        title_string = title_string.strip

        # Remove leading definite articles
        title_string = title_string.gsub(/^(the|an|ná|na|a) /i, "")

        return title_string
      end

      #---------------------------------------------------------------------------------------------------------------
      # Date, Time transformations for indexing
      #---------------------------------------------------------------------------------------------------------------

      # Parse dates sourced from the metadata into properly formatted date ranges for indexing into Solr
      # @param[Hash] dates hash containing all the dates values from the metadata
      # @return Array of formatted dates for indexing (start_date end_date)
      #
      def self.transform_date_ranges(dates={})
        results = []
        dates.each do | key, value |
          value.each do | date_string |
            range = get_date_range date_string
            if range.has_key?('start') && range.has_key?('end')
              results << "#{range['start']} #{range['end']}"
            elsif range.has_key?('start')
              results << "#{range['start']} #{range['start']}"
            end
          end
        end
        return results
      end

      # Parse a date string into an appropriate format for indexing
      # It supports parsing of DCMI Point encoded string as well as ISO8601 string-encoded dates
      # If the date is not in a valid format it will be ignored
      # @param[String]
      # @return Hash hash containing start and date fields, with their values
      def self.get_date_range value
        return {} if value.nil?

        range = Hash.new

        # DCMI Point?
        value.split(/\s*;\s*/).each do |component|
          (k,v) = component.split(/\s*=\s*/)
          begin
            if k.eql?('start')
              range['start'] = ISO8601::DateTime.new(v).year
            elsif k.eql?('end')
              range['end'] = ISO8601::DateTime.new(v).year
            end
          rescue ISO8601::Errors::UnknownPattern => e
            Rails.logger.error("Date #{v} not indexed as it is not compliant with ISO8601!!")
            return {}
          end
        end

        if !range.empty?
          if range.has_key?('start') && !range.has_key?('end')
            range['end'] = range['start'] # date_end = date_start
          end
        else
          # Is it a ISO8601 date range (start/end)?
          date_array = transform_date value
          unless (date_array.empty?)
            range['start'] = date_array[0]
            range['end'] = date_array[1]
          end
        end

        return range
      end

      def self.transform_date(val="")
        dates = []
        if (val.include?("/"))
          range = val.split("/")
          dates = range.collect!.each do |dat|
            begin
              unless dat.include?('/')
                ISO8601::DateTime.new(dat).year
              end
            rescue ISO8601::Errors::UnknownPattern => e
              Rails.logger.error("Date #{dat} not indexed as it is not compliant with ISO8601!!")
              return []
            end
          end
        else
          begin
            # Single date, therefore end date = start date (for correct date range indexing)
            dates[0] = dates[1] = ISO8601::DateTime.new(val).year
          rescue ISO8601::Errors::UnknownPattern => e
            Rails.logger.error("Date #{val} not indexed as it is not compliant with ISO8601!!")
            return []
          end
        end

        dates
      end # transform_date

      def self.iso8601?(value)
        begin
          if value.is_a?(Date) || value.is_a?(Time)
            ISO8601::DateTime.new(value.to_s)
          elsif !value.empty?
            ISO8601::DateTime.new(value)
          end
          return true
        rescue ISO8601::Errors::UnknownPattern => e
          Rails.logger.error("Unable to parse `#{value}' as a date-time object")
          return false
        end
      end

      def self.dcmi_point?(value)
        result = false
        value.split(/\s*;\s*/).each do |component|
          (k,v) = component.split(/\s*=\s*/)

          if k.eql?('name') || k.eql?('start') || k.eql?('end') || k.eql?('scheme')
            result = true
          end
        end
        return result
      end

      def self.create_dcmi_point(name, sdate="", edate="", scheme="")
        return "name=#{name}; #{sdate != '' ? 'start=' << sdate << ';' :''} #{edate != '' ? 'end=' << edate << ';' :''} #{scheme != '' ? 'scheme=' << scheme << ';' :''}"
      end
      # Split date ranges into separate _start and _end SOLR indexes
      #
      # This is not an optimal solution for doing date ranges in SOLR and
      # will have to be updated.
      #def self.transform_date_ranges(dates={})

      # 	results = Hash.new
      #
      #	dates.each do | key, value |
      # 		start = []
      # 		finish = []

      #		value.each do | date_string |
      #			range = date_string.split("/")

      #			if (range.length < 3)
      #				curr_start = nil
      #				curr_finish = nil

      #				if (range.length == 1)
      #					parsed = Chronic.parse(range[0], :guess => false, :context => "past")
      #					if parsed.kind_of? Chronic::Span
      #						curr_start = parsed.begin
      #						curr_finish = parsed.end	
      #					else
      #						curr_start = parsed
      #						curr_finish = parsed
      #					end
      #				else
      #					parsed_start = Chronic.parse(range[0], :guess => false, :context => "past")
      #					parsed_finish = Chronic.parse(range[1], :guess => false, :context => "past")

      #					if parsed_start.kind_of? Chronic::Span
      #						curr_start = parsed_start.begin
      #					else
      #						curr_start = parsed_start
      #					end

      #					if parsed_finish.kind_of? Chronic::Span
      #						curr_finish = parsed_finish.end
      #					else
      #						curr_finish = parsed_finish
      #					end
      #				end

      #				unless curr_start == nil || curr_finish == nil

      #					unless curr_finish < curr_start
      #						start << Solrizer::DefaultDescriptors.iso8601_date(curr_start)
      #						finish << Solrizer::DefaultDescriptors.iso8601_date(curr_finish)
      #					else
      #						start << Solrizer::DefaultDescriptors.iso8601_date(curr_finish)
      #						finish << Solrizer::DefaultDescriptors.iso8601_date(curr_start)
      #					end
      #				end
      #			end
      #		end

      #		if start.length > 0
      #			results.merge!(Solrizer.solr_name(key+"_start", :dateable) => start)
      #			results.merge!(Solrizer.solr_name(key+"_end", :dateable) => finish)
      #		end
      #	end

      #	return results
      #end

      #def self.parse_date(date_input,date_span=true)
      #	lowest_found = nil

      #	year = nil
      #	month = nil
      #	day = nil
      #	hour = nil
      #	min = nil
      #	sec = nil
      #	ms = nil
      #	tz = nil


      #	if (year == nil)
      #		return nil


      #	return date_input
     # end
    end
  end
end