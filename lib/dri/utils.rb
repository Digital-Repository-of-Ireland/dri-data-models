require 'uri'

module DRI
  module Utils
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
  end
end