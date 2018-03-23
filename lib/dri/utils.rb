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
      URI(string_uri)

      true
    rescue URI::InvalidURIError
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
    # @param object [DRI::Batch] the digital object
    def self.checksum_metadata(object)
      if object.attached_files.key?(:descMetadata)
        xml = object.attached_files[:descMetadata].content
        object.metadata_md5 = Checksum.md5_string(xml)
      end
    end

    # Create default reader group permissions for the object and save
    #
    # @param id [DRI::Batch] the PID of the collection object for which
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
    # @param obj [DRI::Batch] the object to check
    def self.retrieve_linked_data(obj)
      if AuthoritiesConfig
        DRI.queue.push(LinkedDataJob.new(obj.id)) unless obj.geographical_coverage.blank?
      end
    rescue Exception => e
      Rails.logger.error "Unable to submit linked data job: #{e.message}"
    end
  end # Module Utils
end # Module DRI
