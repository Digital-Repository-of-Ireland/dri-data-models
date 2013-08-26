module DRI
  module Metadata
    module Transformations
      #require 'chronic'

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
        title_string = title_string.gsub(/\W|\d/, " ").squeeze(" ")

        # Remove starting spaces
        title_string = title_string.strip

        # Remove leading definite articles
        title_string = title_string.gsub(/^the /i, "")

        return title_string
      end

      # Split date ranges into seperate _start and _end SOLR indexes
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
      #					parsed_fnish = Chronic.parse(range[1], :guess => false, :context => "past")

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