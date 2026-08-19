require 'open3'

module DRI::Metadata::Transformations
  module SpatialTransformations
    PROJECTIONS = { 'itm' => '2157', 'ing' => '29903' }.freeze

    def self.from_url(url)
      result = {}
      ld = find_linked_data(url)
      return result if ld.nil?

      geo = ld.spatial
      geojson_hash = JSON.parse(geo, symbolize_names: true)

      result[:json] = geo
      result[:name] = geojson_hash[:properties][:placename]
      result[:coords] = "#{geojson_hash[:geometry][:coordinates][0]} #{geojson_hash[:geometry][:coordinates][1]}"
      result
    end

    def self.find_linked_data(url)
      DRI::LinkedData.find_by(source: url)
    end

    def self.parse_dcmi_point(geospatial_string)
      result = {}

      point = safe_dcmi_components(geospatial_string)
      return result if point.nil?

      # [east_long north_lat]
      return result unless DcmiParser.complete?(DcmiParser::POINT_KEYS, point)

      geometry_crs = nil
      coords = if projected?(point)
                 projection = PROJECTIONS[point['projection'].downcase]
                 geometry_crs = {
                   crs: "http://www.opengis.net/def/crs/EPSG/0/#{projection}",
                   coordinates: [point['east'].delete(',').to_f, point['north'].delete(',').to_f]
                 }

                 giqtrans(projection, point)
               else
                 # projection = 'EPSG:4326'
                 "#{point['east']} #{point['north']}"
               end

      return result if coords.blank?

      result[:coords] = coords
      result[:name] = point['name']
      result[:json] = coords_to_geojson_string([point['name']], coords, geometry_crs)
      result
    end

    def self.parse_dcmi_box(geospatial_string)
      result = {}

      box = safe_dcmi_components(geospatial_string)
      return result if box.nil?

      # [west_long south_lat east_long north_lat]
      return result unless DcmiParser.complete?(DcmiParser::BOX_KEYS, box)

      # Solr 5 changed format to ENVELOPE(minX, maxX, maxY, minY)
      result[:coords] = "ENVELOPE(#{box['westlimit']}, #{box['eastlimit']}, #{box['northlimit']}, #{box['southlimit']})"
      result[:name] = box['name']
      result[:json] = coords_to_geojson_string(
        [box['name']],
        "#{box['westlimit']} #{box['southlimit']} #{box['eastlimit']} #{box['northlimit']}"
      )
      result
    end

    # Transforms a geocode into a Geo Json Hash
    # @param [Array<String>] name [name_en, name_ga] the displayable place name(s) for a geocode value
    # @param [String] coords the string including the coordinates for a geocode value
    # @return [String] the geocode value formatted as a GeoJSON string
    def self.coords_to_geojson_string(name, coords, geometry_crs = nil, uri = nil)
      geojson_hash = { type: 'Feature', geometry: geometry_for(coords), properties: {} }
      geojson_hash[:bbox] = bbox_for(coords) if bbox?(coords)

      name_en, name_ga = name
      display_name = name_ga ? "#{name_ga}/#{name_en}" : name_en

      geojson_hash[:properties][:placename] = display_name if display_name.present?
      geojson_hash[:properties][:geometryCRS] = geometry_crs unless geometry_crs.nil?
      geojson_hash[:properties][:uri] = uri unless uri.blank?
      geojson_hash[:properties][:nameGA] = name_ga if name_ga.present?
      geojson_hash[:properties][:nameEN] = name_en if name_en.present?

      # Return as a JSON String for blacklight-maps
      geojson_hash.to_json.to_s
    end

    def self.giqtrans(source_srid, point)
      east = point['east'].delete(',')
      north = point['north'].delete(',')
      command = "SourceSRID=#{source_srid}&TargetSRID=4937&PreferredDatum=13&Geometry={\"type\":\"Point\",\"coordinates\":[#{east},#{north}]}"

      stdout, = Open3.capture3("#{Settings.plugins.giqtrans_path}/giqtrans", "--CGI=#{command}")

      json = JSON.parse(stdout.lines.last)
      coords = json['coordinates'].join(' ')
      coords == '0 0 0' ? {} : coords
    rescue StandardError
      {}
    end

    def self.bbox?(coords)
      coords.scan(/\s/).length == 3
    end

    def self.point_string?(coords)
      coords.match?(/^[-]?[\d]*[\.]?[\d]*[ ,][-]?[\d]*[\.]?[\d]*$/)
    end

    def self.geometry_for(coords)
      if bbox?(coords)
        { type: 'Polygon', coordinates: [bbox_polygon(coords)] }
      elsif point_string?(coords)
        { type: 'Point', coordinates: point_coordinates(coords) }
      else
        Rails.logger.error("This coordinate format is not yet supported: '#{coords}'")
        {}
      end
    end

    def self.bbox_polygon(coords)
      x_min, y_min, x_max, y_max = coords.split(' ').map(&:to_f)
      [[x_min, y_min], [x_max, y_min], [x_max, y_max], [x_min, y_max], [x_min, y_min]]
    end

    def self.bbox_for(coords)
      coords.split(' ').map(&:to_f)
    end

    def self.point_coordinates(coords)
      array = coords.include?(',') ? coords.split(',').reverse : coords.split(' ')
      array.map(&:to_f)
    end

    def self.projected?(point)
      point['projection'].present? && PROJECTIONS.key?(point['projection'].downcase)
    end

    # Wraps DcmiParser.components, logging and returning nil on any parsing
    # error - matches the original begin/rescue-and-return-empty-hash
    # behavior in parse_dcmi_point/parse_dcmi_box.
    def self.safe_dcmi_components(geospatial_string)
      DcmiParser.components(geospatial_string)
    rescue StandardError => e
      Rails.logger.error("Exception in transform_geospatial: #{geospatial_string} => #{e}")
      nil
    end
  end
end
