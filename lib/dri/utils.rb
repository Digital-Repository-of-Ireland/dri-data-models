# frozen_string_literal: true
require 'uri'

# DRI namespace
module DRI
  # Module Utils - general utilities methods
  module Utils
    # Validates a String URI
    # @param string_uri [String] the string URI
    # return true if valid URI; false otherwise
    #
    def self.valid_uri?(string_uri)
      uri = URI.parse(string_uri)
      %w[http https].include?(uri.scheme)
    rescue URI::BadURIError, URI::InvalidURIError
      false
    end

    # Apply XSLT transformation to input XML. To transform existing
    # descriptive metadata (DC, MODS, EAD) into oai_dc metadata
    #
    # @param xslt_path [String] relative path to the XSLT directory
    # @param xml [Nokogiri::Document] the source xml to be transformed
    # @return [Nokogiri::XML] the resulting xml after XSLT transformation
    #
    def self.apply_xslt_transformation(xslt_path, xml)
      template = Nokogiri::XSLT(File.read(File.join(__dir__, xslt_path)))

      template.transform(xml)
    end

    # Generates metadata checksum for the object
    #
    # @param object [DRI::Base] the digital object
    def self.checksum_metadata(object)
      return unless object.attached_files.key?(:descMetadata)

      xml = object.attached_files[:descMetadata].content
      object.metadata_checksum = Checksum.md5_string(xml)
    end

    # Create default reader group permissions for the object and save
    #
    # @param id [DRI::Base] the PID of the collection object for which
    # to add a default reader group
    def self.create_reader_group(id)
      grp = UserGroup::Group.new(name: id,
                                 description: "Default Reader group for collection #{id}")
      grp.reader_group = true
      grp.save
    end

    # Adds linked data records for logaimn links present
    # in the metadata (geographical_coverage)
    #
    # @param obj [DRI::Base] the object to check
    def self.retrieve_linked_data(obj)
      if AuthoritiesConfig
        DRI.queue.push(LinkedDataJob.new(obj.alternate_id)) if obj.geographical_coverage.present?
      end
    rescue => e
      Rails.logger.error "Unable to submit linked data job: #{e.message}"
    end
  end # Module Utils
end # Module DRI
