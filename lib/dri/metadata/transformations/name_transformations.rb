# frozen_string_literal: true

module DRI::Metadata::Transformations
  # Converts archived-format personal names (e.g. "Lewis, Daniel, Day-")
  # into human-readable display names (e.g. "Daniel Day-Lewis") for indexing.
  module NameTransformations
    NON_PERSON_WORDS = %w[
      ltd ltd. limited archive museum archives library firm nui gallery
      services consultancy associates university
    ].freeze

    # A function to convert an array of names that conform to archiving formatting
    # standards into human-readable names
    # so that a double-quotes search can pick up the full name
    # E.g. "Lewis, Daniel, Day-" is "Daniel Day-Lewis" and
    # "Valera, Eamon, de" is "Eamon de Valera"
    # @param [Array<String>] names the array of metadata people's names
    # @return [Array<String>] the array of transformed metadata people's names
    def transform_name(names = [])
      results = []

      names.each do |archived_name|
        archived_name = extract_name(CGI.unescapeHTML(archived_name))
        next unless person_name?(archived_name)

        name_parts = archived_name.strip.split(',')
        next if name_parts.empty?

        sorted_name = "#{name_parts[0].strip}, #{name_parts[1..].join(' ').strip}"
        parsed_name = Namae.parse(sorted_name)

        result = parsed_name[0].display_order unless parsed_name.empty?
        results |= [result] if result
      end

      results
    end

    def extract_name(name)
      name_remove_dates(name_from_orcid(name))
    end

    def name_from_orcid(name)
      return name unless name.start_with?('name=') && name.index('authority=ORCID')

      end_index = name.index(';') || (name.index('authority') - 1)
      name['name='.length..end_index - 1]
    end

    def name_remove_dates(name)
      name.gsub(/\(?\s*\d+\s*-\s*\d+\s*\)?/, '')
    end

    def person_name?(name)
      return false if name.include?('--') # lcsh style

      downcased = name.downcase
      NON_PERSON_WORDS.none? { |word| downcased.include?(word) }
    end
  end
end
