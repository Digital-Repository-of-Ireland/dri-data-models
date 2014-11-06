module DRI
  module ModelSupport
    module MarcSupport 
     extend ActiveSupport::Concern
      
      def create_marc_records
        if self.new_record?
          return
        end

        xml_without_blanks = Nokogiri::XML.parse(self.fullMetadata.ng_xml.to_xml) do |config|
          config.noblanks
        end
        collection = xml_without_blanks.search("//collection")
        records = collection.children
        collection[0].children.remove
        
        records[1..-1].each do |r|
            collection[0].children.remove
            collection[0].add_child(r)
            create_object collection[0].to_xml
        end
      end

      def create_object xml
        new_object = Batch.with_standard :marc
        new_object.governing_collection = self.governing_collection
        new_object.depositor = self.depositor
        new_object.status = self.status
        new_object.update_metadata xml
        new_object.datastreams['rightsMetadata'].content = self.rightsMetadata.content

        MetadataHelpers.checksum_metadata(new_object)

        if new_object.valid?
          new_object.save
        end
      end        

    end
  end
end
