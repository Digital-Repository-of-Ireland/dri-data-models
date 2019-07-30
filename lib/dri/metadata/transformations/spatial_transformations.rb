require 'open3'

module DRI::Metadata::Transformations
  module SpatialTransformations

    POINT_KEYS = %w(east north)
    BOX_KEYS = %w(eastlimit northlimit westlimit southlimit)

    PROJECTIONS = { 'itm' => '2157', 'ing' => '29903' }

    def self.from_url(url)
      result = {}

      ld = DRI::LinkedData.where(source: url).select { |ld| !ld.spatial.blank? }
      return {} if ld.empty?

      geojson = ld.first.spatial
      geojson.each do |geo|
        geojson_hash = JSON.parse(geo, symbolize_names: true)
        result[:json] = geo
        result[:name] = geojson_hash[:properties][:placename]
        result[:coords] = "#{geojson_hash[:geometry][:coordinates][0]} #{geojson_hash[:geometry][:coordinates][1]}"
      end

      result
    end

    def self.parse_dcmi_point(geospatial_string)
      result = {}

      begin
        point = dcmi_components(geospatial_string)
      rescue Exception => e
        Rails.logger.error("Exception in transform_geospatial: #{geospatial_string} => #{e}")
        return result
      end

      # [east_long north_lat]
      if supported_dcmi?(POINT_KEYS, point)
        coords = if point['projection'].present? && PROJECTIONS.keys.include?(point['projection'].downcase)
                   projection = PROJECTIONS[point['projection'].downcase]

                   geometryCrs = { crs: "http://www.opengis.net/def/crs/EPSG/0/#{projection}" }
                   geometryCrs[:coordinates] = [ point['east'].to_f, point['north'].to_f ]

                   giqtrans(projection, point)
                 else
                  projection = 'ESPG:4326'
                   "#{point['east']} #{point['north']}"
                 end

        return result if coords.blank?

        result[:coords] = coords
        result[:name] = point['name']
        result[:json] = coords_to_geojson_string(point['name'], coords, geometryCrs)
      end

      result
    end

    def self.parse_dcmi_box(geospatial_string)
      result = {}

      begin
        box = dcmi_components(geospatial_string)
      rescue Exception => e
        Rails.logger.error("Exception in transform_geospatial: #{geospatial_string} => #{e}")
        return result
      end
      # [west_long south_lat east_long north_lat]
      if supported_dcmi?(BOX_KEYS, box)
        # Solr 5 changed format to ENVELOPE(minX, maxX, maxY, minY)
        result[:coords] = "ENVELOPE(#{box['westlimit']}, #{box['eastlimit']}, #{box['northlimit']}, #{box['southlimit']})"
        result[:name] = box['name']
        result[:json] = coords_to_geojson_string(box['name'], "#{box['westlimit']} #{box['southlimit']} #{box['eastlimit']} #{box['northlimit']}")
      end

      result
    end

    private

      # Parse geospatial data sourced from the metadata and transform into DCMI Point encoding
      #
      # @param [String] value the metadata coordinates string
      # @return [Array<String>] the transformed metadata coordinates formatter as DCMI Point into a Hash
      #
      def self.dcmi_components(value = nil)
        return {} if value.nil?

        dcmi_components = {}

        value.split(/\s*;\s*/).each do |component|
          (k, v) = component.split(/\s*=\s*/)
          dcmi_components[k.downcase] = v.strip
        end

        dcmi_components
      end

      def self.supported_dcmi?(key_array = [], hash = {})
        key_array.all? { |s| hash.key? s }
      end

      # Transforms a geocode into a Geo Json Hash
      # @param [String] name the displayable place name for a geocode value
      # @param [String] coords the string including the coordinates for a geocode value
      # @return [Hash] the hash including the geocode value formatted in GEO Json
      def self.coords_to_geojson_string(name, coords, geometryCRS = nil)
        geojson_hash = { type: 'Feature', geometry: {}, properties: {} }

        if coords.scan(/[\s]/).length == 3
          # bbox
          coords_array = coords.split(' ').map(&:to_f)
          geojson_hash[:bbox] = coords_array
          geojson_hash[:geometry][:type] = 'Polygon'
          geojson_hash[:geometry][:coordinates] = [[[coords_array[0], coords_array[1]],
                                                    [coords_array[2], coords_array[1]],
                                                    [coords_array[2], coords_array[3]],
                                                    [coords_array[0], coords_array[3]],
                                                    [coords_array[0], coords_array[1]]]]
        elsif coords.match(/^[-]?[\d]*[\.]?[\d]*[ ,][-]?[\d]*[\.]?[\d]*$/)
          # point
          geojson_hash[:geometry][:type] = 'Point'

          coords_array = if coords.match(/,/)
                           coords.split(',').reverse
                         else
                           coords.split(' ')
                         end

          geojson_hash[:geometry][:coordinates] = coords_array.map(&:to_f)
        else
          Rails.logger.error("This coordinate format is not yet supported: '#{coords}'")
        end
        geojson_hash[:properties] = {}
        geojson_hash[:properties][:placename] = name unless name.blank?
        geojson_hash[:properties][:geometryCRS] = geometryCRS unless geometryCRS.nil?

        # Return as a JSON String for blacklight-maps
        geojson_hash.to_json.to_s
      end

      def self.giqtrans(source_srid, point)
        command = "SourceSRID=#{source_srid}&TargetSRID=4937&PreferredDatum=13&Geometry={\"type\":\"Point\",\"coordinates\":[#{point['east']},#{point['north']}]}"
        giqtrans_output = Open3.capture3("#{Settings.plugins.giqtrans_path}/giqtrans --CGI='#{command}'")

        transform = giqtrans_output[0]
        json = JSON.parse(transform.lines.last)

        json['coordinates'].join(' ')
      rescue StandardError => e
        {}
      end

  end
end

