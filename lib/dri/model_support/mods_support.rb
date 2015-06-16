module DRI
  module ModelSupport
    module ModsSupport
      extend ActiveSupport::Concern

      # Implement Mods-specific helper functions
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
        unless (xml_without_blanks.search("/mods:modsCollection").empty?)
          collection = xml_without_blanks.search("/mods:modsCollection")

          records = collection.children

          records.each do |r|
            # Need to add the namespace declarations to the mods:mods root element
            # Otherwise the terminology (xpath) won't find the elements
            new_xml = Nokogiri::XML::Builder.new do |xml|
              xml.mods({"xmlns:mods"=>"http://www.loc.gov/mods/v3"}, r.namespaces) {
                xml.parent.namespace = xml.parent.namespace_definitions.find{|ns| ns.href}
                xml << r.children.to_xml
              }
            end
            # Skip the first one, which has already been generated
            create_object(new_xml.to_xml) if records.index(r) > 0
          end
        end
      end # create_mods_records

      def create_object xml
        doc = Nokogiri::XML(xml)
        if (!doc.xpath("/mods:mods/mods:typeOfResource[@collection='yes']").empty?)
          new_object = DRI::Batch.with_standard :mods_collection
        else
          new_object = DRI::Batch.with_standard :mods_record
        end
        new_object.governing_collection = self
        new_object.depositor = self.depositor
        new_object.status = self.status
        new_object.update_metadata xml
        new_object.permissions = self.permissions.to_a

        # Assign collection membership - only for collections (hasCollectionMember and isMemberOfCollection)
        if (new_object.is_collection? && self.is_collection?)
          new_object.parent_collection = self
        end

        MetadataHelpers.checksum_metadata(new_object)

        if new_object.valid?
          new_object.save
        end
      end # create_object
    end # modsSupport
  end # modelSupport
end # DRI
