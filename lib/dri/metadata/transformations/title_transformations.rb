# frozen_string_literal: true

module DRI::Metadata::Transformations
  module TitleTransformations
    # A function to convert a title string removing definite articles, unnecessary spaces, etc.
    #
    # @param [String] title_string the metadata title string
    # @return [String] the transformed metadata title string
    def transform_title_for_sort(title_string = '')
      # Space out non-word and non-number characters, squeeze the spaces, and trim
      title_string = title_string.gsub(/[^[:alnum:]]/, ' ').squeeze(' ').strip

      # Remove leading definite articles
      title_string = title_string.gsub(/^(the|an|ná|na|a) /i, '')

      title_string.downcase
    end
  end
end
