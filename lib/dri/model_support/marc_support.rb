module DRI
  module ModelSupport
    module MarcSupport 
     extend ActiveSupport::Concern
      
      def create_marc_records
        if self.new_record?
          return
        end
        xml_no_namespaces = self.fullMetadata.ng_xml.clone
        xml_no_namespaces.remove_namespaces!
        xml_without_blanks = Nokogiri::XML.parse(xml_no_namespaces.to_xml) do |config|
          config.noblanks
        end
        collection = xml_without_blanks.search("//collection")
        records = collection.children
        collection[0].children.remove
        
        records[1..-1].each do |r|
          create_object r.to_xml
        end
      end

      def create_object xml
        new_object = DRI::Batch.with_standard :marc
        if !self.governing_collection.nil?
          new_object.governing_collection = self.governing_collection
        else
          new_object.governing_collection = self
        end
        new_object.depositor = self.depositor
        new_object.status = self.status
        new_object.update_metadata xml
        new_object.permissions = self.permissions.to_a

        MetadataHelpers.checksum_metadata(new_object)

        if new_object.valid?
          new_object.save
        end
      end        

    end
  end
end
