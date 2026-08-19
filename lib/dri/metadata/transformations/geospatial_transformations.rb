# frozen_string_literal: true

module DRI::Metadata::Transformations
  # Parses geospatial metadata values (DCMI Point, DCMI Box, or a URL
  # pointing at linked-data spatial info) into the coordinate/name/JSON
  # values used for Solr indexing.
  module GeospatialTransformations
    # Parse geospatial data sourced from the metadata into Point or BBox for indexing into Solr
    #
    # @param [Hash] geodata the hash containing all the geo values from the metadata
    # @return [Hash] parsed geospatial strings for indexing
    def transform_geospatial(geodata = {})
      results = { coords: [], name: [], json: [] }

      geodata.each_value do |values|
        values.each do |geo_string|
          next if geo_string.blank?

          result = parse_geo_string(geo_string)
          next if result.blank?

          results[:coords].push(result[:coords]) if result[:coords].present?
          results[:name].push(result[:name]) unless result[:name].nil?
          results[:json].push(result[:json]) if result[:json].present?
        end
      end

      results[:json] = filter_projections(results[:json])
      results
    end

    def filter_projections(geojson_strings)
      features = geojson_strings.map { |geojson_string| JSON.parse(geojson_string) }

      ['http://www.opengis.net/def/crs/EPSG/0/2157', 'http://www.opengis.net/def/crs/EPSG/0/29903'].each do |projection|
        filtered = features.select { |feature| feature['properties'].dig('geometryCRS', 'crs') == projection }
        return filtered.map { |feature| feature.to_json.to_s } if filtered.present?
      end

      features.map { |feature| feature.to_json.to_s }
    end

    # Transforms a geocode string encoded using DCMI Point or Box into a suitable formatted string of
    # coordinates for their indexing in the geographical indices.
    # E.g. Box: 'eastlimit, northlimit, westlimit, southlimit'
    #      Point: 'east north'
    # @param [String] geo_string the geocode string encoded in DCMI Point or Box
    # @return [String] the string containing the geocode coordinates suitable for geographic indexing
    def get_spatial_coordinates(geo_string)
      components = DcmiParser.components(geo_string)

      if DcmiParser.point?(geo_string)
        point_coordinate_string(components)
      elsif DcmiParser.box?(geo_string)
        box_coordinate_string(components)
      else
        ''
      end
    end

    private

    def parse_geo_string(geo_string)
      if DcmiParser.point?(geo_string)
        SpatialTransformations.parse_dcmi_point(geo_string)
      elsif DcmiParser.box?(geo_string)
        SpatialTransformations.parse_dcmi_box(geo_string)
      elsif geo_string =~ /\A#{URI.regexp(['http', 'https'])}\z/
        SpatialTransformations.from_url(geo_string)
      else
        { name: geo_string } # not a point or box so index string into placename solr field
      end
    end

    def point_coordinate_string(components)
      lat = components['east'].to_s.strip
      long = components['north'].to_s.strip

      return '' if lat.empty? || long.empty?

      "#{lat} #{long}"
    end

    def box_coordinate_string(components)
      eastlimit = components['eastlimit'].to_s.strip
      northlimit = components['northlimit'].to_s.strip
      westlimit = components['westlimit'].to_s.strip
      southlimit = components['southlimit'].to_s.strip

      return '' if [eastlimit, northlimit, westlimit, southlimit].any?(&:empty?)

      "#{westlimit} #{southlimit} #{eastlimit} #{northlimit}"
    end
  end
end
