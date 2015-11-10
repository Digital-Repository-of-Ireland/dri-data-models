require 'uri'

module DRI
  module Utils
    def self.split_id(pid)
      pid.sub("#{Rails.application.config.id_namespace}:", '')
    end

    # Validates a String URI
    # @param[String] the string URI
    # return true if valid URI; false otherwise
    #
    def self.valid_uri?(string_uri)
      URI(string_uri)

      true
    rescue URI::InvalidURIError
      false
    end

    # Returns a Hash with the components of a DCMI Period encoded string
    # @param[String] the encoded DCMI Period
    # @return Hash with the DCMI Period components
    #
    def self.decode_dcmi_period(encoded_period)
      dcmi_period_hash = {}

      name_s = encoded_period.scan(/name=(.*?);/)
      dcmi_period_hash['name'] = name_s.first unless name_s.empty?
      start_s = encoded_period.scan(/start=(.*?);/)
      dcmi_period_hash['start'] = start_s.first unless start_s.empty?
      end_s = encoded_period.scan(/end=(.*?);/)
      dcmi_period_hash['end'] = end_s.first unless end_s.empty?
      scheme_s = encoded_period.scan(/scheme=(.*?);/)
      dcmi_period_hash['scheme'] = scheme_s.first unless scheme_s.empty?

      dcmi_period_hash
    end

    # Returns a Hash with the components of a DCMI Point encoded string
    # @param[String] the encoded DCMI Period
    # @return Hash with the DCMI Point components
    #
    def self.decode_dcmi_point(encoded_point)
      # TODO: Implement
      dcmi_point_hash = {}

      dcmi_point_hash
    end

    # Apply XSLT transformation to input XML. To transform existing
    # descriptive metadata (DC, MODS, EAD) into oai_dc metadata
    # @param[String] xslt_path relative path to the XSLT directory
    # @param[Nokogiri::Document] xml the source xml to be transformed
    # @return Nokogiri::XML the resulting xml after XSLT transformation
    #
    def self.apply_xslt_transformation(xslt_path, xml)
      template = Nokogiri::XSLT(File.read(File.join(__dir__, xslt_path)))

      template.transform(xml)
    end

    # Generates metadata checksum for the object
    # @param object [DRI::Batch] the digital object
    def self.checksum_metadata(object)
      if object.attached_files.key?(:descMetadata)
        xml = object.attached_files[:descMetadata].content
        object.metadata_md5 = Checksum.md5_string(xml)
      end
    end

    # Create deafult reader group permissions for the object and save
    # @param object [DRI::Batch] the object for which
    # to add a default reader group
    def self.create_reader_group(id)
      grp = UserGroup::Group.new(name: id,
                                 description: "Default Reader group for collection #{id}")
      grp.reader_group = true
      grp.save
    end

    # Adds linked data records for logaimn links present
    # in the metadata (geographical_coverage)
    # @param obj [DRI::Batch] the object to check
    def self.retrieve_linked_data(obj)
      if AuthoritiesConfig
        begin
          Sufia.queue.push(LinkedDataJob.new(obj.id)) unless obj.geographical_coverage.blank?
        rescue Exception => e
          Rails.logger.error "Unable to submit linked data job: #{e.message}"
        end
      end
    end
  end # Module Utils
end # Module DRI
