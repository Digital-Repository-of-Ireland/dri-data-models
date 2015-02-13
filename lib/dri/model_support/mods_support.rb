module DRI
  module ModelSupport
    module ModsSupport
      extend ActiveSupport::Concern

      # TODO Implement Mods-specific helper functions
      def create_mods_records
        if self.new_record?
          return
        end
        xml_without_blanks = Nokogiri::XML.parse(self.fullMetadata.ng_xml.to_xml) do |config|
          config.noblanks
        end

        # Remove namespaces before iterating over the list of mods records
        #xml_no_ns = xml_without_blanks.remove_namespaces!
        #collection = xml_no_ns.search("/modsCollection")
        collection = xml_without_blanks.search("/mods:modsCollection")
        records = collection.children

        records.each.with_index(1) do |r, idx|
          create_object(r.to_xml)
        end
      end # create_mods_records

      def create_object xml
        new_object = DRI::Batch.with_standard :mods
        new_object.governing_collection = self.governing_collection
        new_object.depositor = self.depositor
        new_object.status = self.status
        new_object.update_metadata xml
        new_object.datastreams['rightsMetadata'].content = self.rightsMetadata.content

        MetadataHelpers.checksum_metadata(new_object)

        if new_object.valid?
          new_object.save
        end
      end # create_object
    end # modsSupport
  end # modelSupport
end # DRI