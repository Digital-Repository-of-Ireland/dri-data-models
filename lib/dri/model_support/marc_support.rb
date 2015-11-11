module DRI
  module ModelSupport
    module MarcSupport
      extend ActiveSupport::Concern

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

      def create_object(xml)
        new_object = DRI::Batch.with_standard(:marc)
        if governing_collection.nil?
          new_object.governing_collection = self
        else
          new_object.governing_collection = governing_collection
        end
        new_object.depositor = depositor
        new_object.status = status
        new_object.update_metadata(xml)
        new_object.permissions = permissions.to_a
        MetadataHelpers.checksum_metadata(new_object)

        new_object.save if new_object.valid?
      end
    end
  end
end
