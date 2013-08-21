module DRI
  module Metadata
    module Transformations

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
    end
  end
end