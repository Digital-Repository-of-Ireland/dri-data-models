module DRI
  class Mods < DRI::Batch
    include DRI::ModelSupport::ModsSupport

    # MODS record identifier, not multi-valued
    has_attributes :identifier, datastream: :descMetadata, multiple: false
    has_attributes :doi, datastream: :descMetadata, multiple: false
    has_attributes :uri, datastream: :descMetadata, multiple: false
    # Title
    has_attributes :subtitle, datastream: :descMetadata, multiple: true
    # Description
    has_attributes :abstract, datastream: :descMetadata, multiple: true
    has_attributes :toc, datastream: :descMetadata, multiple: true
    has_attributes :note, datastream: :descMetadata, multiple: true
    # Source
    has_attributes :source, datastream: :descMetadata, multiple: true
    # Dates
    has_attributes :date, datastream: :descMetadata, multiple: true
    has_attributes :date_captured, datastream: :descMetadata, multiple: true
    has_attributes :date_other, datastream: :descMetadata, multiple: true
    # TODO - Ask Marta, Physical Description - Optional in the guidelines
    #has_attributes :physical_description, datastream: :descMetadata, multiple: true

    has_attributes :subject_name, datastream: :descMetadata, multiple: true
    # Geographical, temporal
    has_attributes :geographical_coverage, datastream: :descMetadata, multiple: true
    has_attributes :temporal_coverage, datastream: :descMetadata, multiple: true
    has_attributes :subject_date_start, datastream: :descMetadata, multiple: true
    has_attributes :subject_date_end, datastream: :descMetadata, multiple: true
    has_attributes :subject_temporal, datastream: :descMetadata, multiple: true

    # Roles
    has_attributes  *(DRI::Vocabulary::marcRelators.map { |s| s.prepend("role_").to_sym}), datastream: :descMetadata,
                    multiple: true

    around_save :create_multiple_records

    # Initialize - mods collection | mods record
    def initialize(type, args = {})
      case type
        when :collection
          metadata_class = "DRI::Metadata::ModsCollection"
        else
          metadata_class = "DRI::Metadata::Mods"
      end
      args[:desc_metadata_class] = metadata_class

      super(args)
    end

    def attributes=(properties)
      super(properties)
    end

    def update_metadata xml_text
      if (xml_text.is_a? File)
        xml_text = xml_text.read
      end

      if (xml_text.is_a? Nokogiri::XML::Document)
        xml = xml_text
      else
        xml = Nokogiri::XML xml_text
      end

      xml_without_blanks = Nokogiri::XML.parse(xml.to_xml) do |config|
        config.noblanks
      end

      fullMetadata.ng_xml = xml_without_blanks
      # Important, we remove all the namespaces for descriptiveMetadata
      # object = split_xml xml_without_blanks.remove_namespaces!
      object = split_xml xml_without_blanks
      descMetadata.ng_xml = object

      return true
    end

    def roles= roles
      if (descMetadata.class == DRI::Metadata::Mods)
        descMetadata.roles = roles
      end
    end

    def split_xml xml_text
      unless xml_text.search("/mods:modsCollection").empty?
        collection = xml_text.search("/mods:modsCollection")
        mods_records = collection.children
        record = mods_records[0]

        # Return the first record
        return record.to_xml
      end
      # This is an individual record, therefore return all XML
      return xml_text
    end

    def self.find_or_create(pid)
      begin
        DRI::Mods.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
        DRI::Mods.create({pid: pid})
      end
    end

    def create_multiple_records
      yield # Do save the object
      # Check whether there are namespaces
      if self.fullMetadata.ng_xml.namespaces.values.include?("http://www.loc.gov/mods/v3")
        # Get the prefix used in the XML for MODS
        ns_array = self.fullMetadata.ng_xml.namespaces.select{ |key, hash| hash == "http://www.loc.gov/mods/v3"}.first
        prefix = ns_array.first.to_s.dup
        prefix.slice! "xmlns:"

        query = self.fullMetadata.ng_xml.search("//#{prefix}:mods")
      else
        query = self.fullMetadata.ng_xml.search("//mods")
      end

      if !new_record? && query.count > 1
        begin
          Sufia.queue.push(CreateModsRecordsJob.new(self.pid))
        rescue Exception => e
          logger.error(e.message)
        end
      end
    end
  end # class
end # module