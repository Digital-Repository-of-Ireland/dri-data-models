# frozen_string_literal: true
# DRI namespace
module DRI
  # ModelSupport namespace
  module ModelSupport
    # Includes methods to handle MARC metadata, record creation
    module ModsSupport
      extend ActiveSupport::Concern

      # Creates a set of DRI::Mods digital objects from the MODS record metadata
      def create_mods_records
        return if new_record?
        xml_no_blanks = Nokogiri::XML.parse(fullMetadata.to_xml, &:noblanks)

        return if xml_no_blanks.search('/mods:modsCollection').empty?

        collection = xml_no_blanks.search('/mods:modsCollection')
        records = collection.children
        records.each_with_index do |r, i|
          next if i.zero?

          # Need to add the namespace declarations to the mods:mods root element
          # Otherwise the terminology (xpath) won't find the elements
          new_xml = Nokogiri::XML::Builder.new do |xml|
            xml.mods({ 'xmlns:mods' => 'http://www.loc.gov/mods/v3' }, r.namespaces) {
              xml.parent.namespace = xml.parent.namespace_definitions.find(&:href)
              xml << r.children.to_xml
            }
          end
          # Skip the first one, which has already been generated
          create_object(new_xml.to_xml) if records.index(r).positive?
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

        DRI::Utils.checksum_metadata(new_object)

        new_object.save if new_object.valid?
        save
      end # create_object
    end # modsSupport
  end # modelSupport
end # DRI
