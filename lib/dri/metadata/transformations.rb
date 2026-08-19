require 'iso8601'
require 'dri/metadata/transformations/dcmi_parser'
require 'dri/metadata/transformations/name_transformations'
require 'dri/metadata/transformations/title_transformations'
require 'dri/metadata/transformations/date_transformations'
require 'dri/metadata/transformations/geospatial_transformations'
require 'dri/metadata/transformations/spatial_transformations'

# DRI namespace
module DRI
  # Metadata namespace
  module Metadata
    # Implements general, common methods, used in descMetadata classes for handling metadata transformations for
    # indexing.
    #
    # The actual method bodies live in the sibling files under
    # transformations/ (name_transformations.rb, date_transformations.rb,
    # etc.), organized by concern.
    module Transformations
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

      extend NameTransformations
      extend TitleTransformations
      extend DateTransformations
      extend GeospatialTransformations

      # Determines whether a geocode string is formatted according to DCMI Point
      # @param [String] value the geocode string
      # @return [Boolean] true if DCMI Point formatted; false otherwise
      def self.dcmi_point?(value)
        DcmiParser.point?(value)
      end

      # Determines whether a geocode string is formatted according to DCMI Box
      # @param [String] value the geocode string
      # @return [Boolean] true if DCMI Box formatted; false otherwise
      def self.dcmi_box?(value)
        DcmiParser.box?(value)
      end

      # Determines whether a date string is formatted according to DCMI Period
      # @param [String] value the date string
      # @return [Boolean] true if DCMI Period formatted; false otherwise
      def self.dcmi_period?(value)
        DcmiParser.period?(value)
      end

      # Determines whether a string is encoded using DCMI Box, Point or Period
      # @param [String] value the string to check
      # @return [Boolean] true if DCMI Box, Point or Period encoded; false otherwise
      def self.dcmi_encoded?(value)
        DcmiParser.encoded?(value)
      end
    end
  end
end
