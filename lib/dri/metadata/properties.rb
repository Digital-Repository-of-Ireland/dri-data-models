module DRI

  module Metadata

    class Properties < ActiveFedora::NokogiriDatastream

      # OM (Opinionated Metadata) terminology mapping
      set_terminology do |t|
        t.root(:path=>"properties", :xmlns => '', :namespace_prefix => nil)  # Selects the root node of the XML document
        t.status(:namespace_prefix=>nil, :index_as=>[:displayable, :facetable])
        t.model_version(:path=>"properties/modelVersion", :namespace_prefix => nil)
	t.resource(:namespace_prefix => nil) {
          t.datastream(:path=>{:attribute=>"ds"}, :namespace_prefix=>nil)
	  t.model_version(:path=>"modelVersion", :namespace_prefix=>nil)

          # Starting out with 'sha256' and 'md5', simply add more checksum types if needed
	  t.sha256(:path=>"checksum", :attributes=>{:type=>"sha256"}, :namespace_prefix=>nil)
	  t.md5(:path=>"checksum", :attributes=>{:type=>"md5"}, :namespace_prefix=>nil)
	}
	t.resource_datastream(:proxy=>[:resource, :datastream])
        t.resource_md5(:proxy=>[:resource, :md5])
        t.resource_sha256(:proxy=>[:resource, :sha256])
      end # set_terminology

      # Build the default XML document
      def self.xml_template
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.properties {
                 xml.status "draft"
            }
          end
          return builder.doc
      end

    end

  end

end
