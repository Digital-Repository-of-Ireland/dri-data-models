require 'uri'

module DRI
  module Utils
    # Validates a String URI
    # @param[String] the string URI
    # return true if valid URI; false otherwise
    #
    def self.valid_uri? string_uri
      new_uri = nil
      begin
        new_uri = URI(string_uri)

        return true
      rescue URI::InvalidURIError => e
        logger.error("Error valid_uri?: #{new_uri}, #{e}")
        return false
      end
    end

    # Returns a Hash with the components of a DCMI Period encoded string
    # @param[String] the encoded DCMI Period
    # @return Hash with the DCMI Period components
    #
    def self.decode_dcmi_period encoded_period
      dcmi_period_hash = Hash.new

      name_s = encoded_period.scan(/name=(.*?);/)
      dcmi_period_hash["name"] = name_s.first unless name_s.empty?
      start_s = encoded_period.scan(/start=(.*?);/)
      dcmi_period_hash["start"] = start_s.first unless start_s.empty?
      end_s = encoded_period.scan(/end=(.*?);/)
      dcmi_period_hash["end"] = end_s.first unless end_s.empty?
      scheme_s = encoded_period.scan(/scheme=(.*?);/)
      dcmi_period_hash["scheme"] = scheme_s.first unless scheme_s.empty?

      return dcmi_period_hash
    end

    # Returns a Hash with the components of a DCMI Point encoded string
    # @param[String] the encoded DCMI Period
    # @return Hash with the DCMI Point components
    #
    def self.decode_dcmi_point encoded_point
      # TODO Implement
      dcmi_point_hash = Hash.new

      return dcmi_point_hash
    end
  end # Module Utils
end # Module DRI