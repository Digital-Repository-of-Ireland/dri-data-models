module DRI
  module ModelSupport
    module ModsSupport
      extend ActiveSupport::Concern

      # Implement Mods-specific helper functions
      def create_mods_records
        return if self.new_record?

        xml_no_blanks = Nokogiri::XML.parse(fullMetadata.ng_xml.to_xml, &:noblanks)

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

      def create_object(xml)
        new_object = DRI::Batch.with_standard :mods
        new_object.governing_collection = self
        new_object.depositor = depositor
        new_object.status = status
        new_object.update_metadata(xml)
        new_object.permissions = permissions.to_a
        DRI::Utils.checksum_metadata(new_object)

        # Assign collection membership - only for collections
        # (hasCollectionMember and isMemberOfCollection)
        # if new_object.collection? && self.collection?
        #   new_object.parent_collection = self
        # end

        new_object.save if new_object.valid?
      end # create_object
    end # modsSupport
  end # modelSupport
end # DRI
