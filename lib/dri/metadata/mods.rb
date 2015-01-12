module DRI

  module Metadata

    # An ActiveFedora datastream that interacts with MODS.

    class Mods < DRI::Metadata::Base

      # Set OM (Opinionated Metadata) terminology
      def self.load_inherited_terminology
        set_terminology do |t|
          t.root(:path=>"mods", :xmlns=>"http://www.loc.gov/mods/v3",
                 :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-5.xsd")
        end

      end

      # Build the xml doc
      def self.xml_template
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.mods(:version=>"3.5", "xmlns:xlink"=>"http://www.w3.org/1999/xlink",
              "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
              "xmlns"=>"http://www.loc.gov/mods/v3",
              "xsi:schemaLocation"=>"http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-5.xsd") {
            }
          end
          return builder.doc
      end

      def synchronize_metadata_on_save
        false
      end

      # Load terminology
      load_inherited_terminology      
    end # class
    
  end # module

end # module
