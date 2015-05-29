module DRI
  module Metadata
    module Transformations
      #require 'chronic'
      require 'iso8601'

      CREATION_DATE_RANGE_SOLR_FIELD = "cdateRange"
      PUBLISHED_DATE_RANGE_SOLR_FIELD = "pdateRange"
      SUBJECT_DATE_RANGE_SOLR_FIELD = "sdateRange"
      GEOSPATIAL_SOLR_FIELD = "geospatial"
      GEOJSON_SOLR_FIELD = "geojson_ssim" # Solrizer only creates _tesim; for BL Maps we need _ssim
      PLACENAME_SOLR_FIELD = "placename_field"

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

      # Parse geospatial data sourced from the metadata into Point or BBox for indexing into Solr
      # @param[Hash] geodata hash containing all the geo values from the metadata
      # @return Array of formatted coordinates or bbox for indexing
      #
      def self.transform_geospatial(geodata={})
        results = Hash.new
        results[:coords] = []
        results[:name] = []
        results[:json] = []
        geodata.each do | key, value |
          value.each do | geo_string |
            if (dcmi_point? geo_string)
              begin
               point = get_geo_point(geo_string)
              rescue Exception => e
                Rails.logger.error("Exception in transform_geospatial: #{geo_string} => #{e.to_s}")
                break
              end
              # [east_long north_lat]
              if point.has_key?('east') && point.has_key?('north') && point.has_key?('name')
                results[:coords] << "#{point['east']} #{point['north']}"
                results[:name] << point['name']
                results[:json] << geojson_string_from_coords(point['name'], "#{point['east']} #{point['north']}")
              end
            elsif (dcmi_box? geo_string)
              begin
                box = get_geo_box(geo_string)
              rescue Exception => e
                Rails.logger.error("Exception in transform_geospatial: #{geo_string} => #{e.to_s}")
                break
              end
              # [west_long south_lat east_long north_lat]
              if box.has_key?('name') && box.has_key?('eastlimit') && box.has_key?('northlimit') && box.has_key?('westlimit') && box.has_key?('southlimit')
                results[:coords] << "#{box['westlimit']} #{box['southlimit']} #{box['eastlimit']} #{box['northlimit']}"
                results[:name] << box['name']
                results[:json] << geojson_string_from_coords(box['name'], "#{box['westlimit']} #{box['southlimit']} #{box['eastlimit']} #{box['northlimit']}")
              end
            elsif (geo_string =~ /\A#{URI::regexp(['http', 'https'])}\z/)
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
        return results
      end

      def self.get_geo_point value
        return {} if value.nil?

        point = Hash.new

        # DCMI Point?
        value.split(/\s*;\s*/).each do |component|
          (k,v) = component.split(/\s*=\s*/)
          if k.eql?('east')
            point['east'] = v.strip
          elsif k.eql?('north')
            point['north'] = v.strip
          elsif k.eql?('name')
            point['name'] = v.strip
          end
        end

        return point
      end

      def self.get_geo_box value
        return {} if value.nil?

        box = Hash.new

        value.split(/\s*;\s*/).each do |component|
          (k,v) = component.split(/\s*=\s*/)
          if k.eql?('northlimit')
            box['northlimit'] = v.strip
          elsif k.eql?('eastlimit')
            box['eastlimit'] = v.strip
          elsif k.eql?('southlimit')
            box['southlimit'] = v.strip
          elsif k.eql?('westlimit')
            box['westlimit'] = v.strip
          elsif k.eql?('name')
            box['name'] = v.strip
          end
        end

        return box
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

        # DCMI Period?
        value.split(/\s*;\s*/).each do |component|
          (k,v) = component.split(/\s*=\s*/)
          begin
            if k.eql?('start')
              range['start'] = ISO8601::DateTime.new(v).year
            elsif k.eql?('end')
              range['end'] = ISO8601::DateTime.new(v).year
            end
          rescue ISO8601::Errors::StandardError => e
            Rails.logger.error("Date #{v} not indexed as it is not compliant with ISO8601. Error: #{e.to_s}.")
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
            rescue ISO8601::Errors::StandardError => e
              Rails.logger.error("Date #{dat} not indexed as it is not compliant with ISO8601. Error: #{e.to_s}.")
              return []
            end
          end
        else
          begin
            # Single date, therefore end date = start date (for correct date range indexing)
            dates[0] = dates[1] = ISO8601::DateTime.new(val).year
          rescue ISO8601::Errors::StandardError => e
            Rails.logger.error("Date #{val} not indexed as it is not compliant with ISO8601. Error: #{e.to_s}.")
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
        rescue ISO8601::Errors::StandardError => e
          Rails.logger.error("Unable to parse `#{value}' as a date-time object. Error: #{e.to_s}.")
          return false
        end
      end

      #---------------------
      # Helper Functions
      #---------------------

      def self.dcmi_period?(value)
        result = false
        value.split(/\s*;\s*/).each do |component|
          (k,v) = component.split(/\s*=\s*/)

          if ['start', 'end', 'scheme'].include? k
            result = true
          end
        end
        return result
      end

      def self.dcmi_point?(value)
        result = false
        value.split(/\s*;\s*/).each do |component|
          (k,v) = component.split(/\s*=\s*/)

          if ['east', 'north', 'elevation'].include? k
            result = true
          end
        end
        return result
      end

      def self.dcmi_box?(value)
        result = false
        value.split(/\s*;\s*/).each do |component|
          (k,v) = component.split(/\s*=\s*/)

          if ['eastlimit', 'northlimit', 'southlimit', 'westlimit', 'uplimit', 'downlimit'].include? k
            result = true
          end
        end
        return result
      end

      def self.create_dcmi_period(name, sdate="", edate="", scheme="")
        return "name=#{name}; #{sdate != '' ? 'start=' << sdate << ';' :''} #{edate != '' ? 'end=' << edate << ';' :''} #{scheme != '' ? 'scheme=' << scheme << ';' :''}"
      end

      # Taken from maps_controller and adapted
      def self.geojson_string_from_coords(name, coords)
        geojson_hash = {type: "Feature", geometry: {}, properties: {}}
        if coords.scan(/[\s]/).length == 3 # bbox
          coords_array = coords.split(' ').map { |v| v.to_f }
          geojson_hash[:bbox] = coords_array
          geojson_hash[:geometry][:type] = "Polygon"
          geojson_hash[:geometry][:coordinates] = [[[coords_array[0],coords_array[1]],
                                                    [coords_array[2],coords_array[1]],
                                                    [coords_array[2],coords_array[3]],
                                                    [coords_array[0],coords_array[3]],
                                                    [coords_array[0],coords_array[1]]]]
        elsif coords.match(/^[-]?[\d]*[\.]?[\d]*[ ,][-]?[\d]*[\.]?[\d]*$/) # point
          geojson_hash[:geometry][:type] = "Point"
          if coords.match(/,/)
            coords_array = coords.split(',').reverse
          else
            coords_array = coords.split(' ')
          end
          geojson_hash[:geometry][:coordinates] = coords_array.map { |v| v.to_f }
        else
          Rails.logger.error("This coordinate format is not yet supported: '#{coords}'")
        end
        geojson_hash[:properties] = {}
        geojson_hash[:properties][:placename] = name

        # Return as a JSON String for blacklight-maps
        geojson_hash.to_json.to_s
      end

      def self.get_spatial_coordinates geo_string
        coordinates = lat = long = eastlimit = northlimit = westlimit = southlimit = ""

        if DRI::Metadata::Transformations.dcmi_point?(geo_string)
          geo_string.split(/\s*;\s*/).each do |component|
            (k,v) = component.split(/\s*=\s*/)
            if k.eql?('east')
              lat = v.strip unless v.nil? || v.empty?
            elsif k.eql?('north')
              long = v.strip unless v.nil? || v.empty?
            end
          end
          if (!lat.empty? && !long.empty?)
            coordinates = "#{lat} #{long}"
          end
        elsif DRI::Metadata::Transformations.dcmi_box?(geo_string)
          geo_string.split(/\s*;\s*/).each do |component|
            (k,v) = component.split(/\s*=\s*/)
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
          if (!eastlimit.empty? && !northlimit.empty? && !westlimit.empty? && !southlimit.empty?)
            coordinates = "#{westlimit} #{southlimit} #{eastlimit} #{northlimit}"
          end
        end

        return coordinates
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
      #			results.merge!(ActiveFedora::SolrQueryBuilder.solr_name(key+"_start", :dateable) => start)
      #			results.merge!(ActiveFedora::SolrQueryBuilder.solr_name(key+"_end", :dateable) => finish)
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
