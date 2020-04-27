# DRI namespace
module DRI
  # ModelSupport namespace
  module ModelSupport
    # Includes methods to handle MARC metadata, record creation
    module MarcSupport
      extend ActiveSupport::Concern

      # Creates a set of DRI::Marc digital objects from the MARC record metadata
      def create_marc_records
        return if self.new_record?

        xml_no_ns = fullMetadata.ng_xml.clone
        xml_no_ns.remove_namespaces!
        xml_no_blanks = Nokogiri::XML.parse(xml_no_ns.to_xml, &:noblanks)
        collection = xml_no_blanks.search('//collection')
        records = collection.children
        collection[0].children.remove

        records[1..-1].each { |r| create_object(r.to_xml) }
      end

      # Create a new DRI::Marc digital object and sets its descMetadata from XML
      # @param [String] xml the XML metadata for the digital object to be created
      #
      def create_object(xml)
        new_object = DRI::DigitalObject.with_standard(:marc)
        if governing_collection.nil?
          new_object.governing_collection = self
        else
          new_object.governing_collection = governing_collection
        end
        new_object.depositor = depositor
        new_object.status = status
        new_object.update_metadata(xml)
        new_object.permissions = permissions.to_a
        DRI::Utils.checksum_metadata(new_object)

        new_object.save if new_object.valid?
      end
    end
  end
end
