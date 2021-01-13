# DRI namespace
module DRI
  # ModelSupport namespace
  module ModelSupport
    # Includes methods to handle MARC metadata, record creation
    module ModsSupport
      extend ActiveSupport::Concern

      # Creates a set of DRI::Mods digital objects from the MODS record metadata
      def create_mods_records
        return if self.new_record?
        xml_no_blanks = Nokogiri::XML.parse(fullMetadata.to_xml, &:noblanks)

        return if xml_no_blanks.search('/mods:modsCollection').empty?

        collection = xml_no_blanks.search('/mods:modsCollection')
        records = collection.children
        records.each_with_index do |r, i|
          next if i == 0

          # Need to add the namespace declarations to the mods:mods root element
          # Otherwise the terminology (xpath) won't find the elements
          new_xml = Nokogiri::XML::Builder.new do |xml|
            xml.mods({ 'xmlns:mods' => 'http://www.loc.gov/mods/v3' }, r.namespaces) {
              xml.parent.namespace = xml.parent.namespace_definitions.find(&:href)
              xml << r.children.to_xml
            }
          end
          # Skip the first one, which has already been generated
          create_object(new_xml.to_xml) if records.index(r) > 0
        end
      end # create_mods_records

      # Create a new DRI::Mods digital object and sets its descMetadata from XML
      # @param [String] xml the XML metadata for the digital object to be created
      #
      def create_object(xml)
        new_object = DRI::Mods.new
        new_object.governing_collection = self
        new_object.depositor = depositor
        new_object.status = status
        new_object.update_metadata(xml)

        new_object.read_users_string = read_users_string
        new_object.read_groups_string = read_groups_string
        new_object.edit_users_string = edit_users_string
        new_object.edit_groups_string = edit_groups_string
        new_object.manager_users_string = manager_users_string
        new_object.manager_groups_string = manager_groups_string

        DRI::Utils.checksum_metadata(new_object)

        new_object.save if new_object.valid?
        self.save
      end # create_object
    end # modsSupport
  end # modelSupport
end # DRI
