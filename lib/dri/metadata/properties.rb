module DRI

  module Metadata

    class Properties < ActiveFedora::OmDatastream

      # OM (Opinionated Metadata) terminology mapping
      set_terminology do |t|
        t.root(:path=>"properties", :xmlns => '', :namespace_prefix => nil)  # Selects the root node of the XML document
        t.status(:namespace_prefix=>nil, :index_as=>[:symbol, :stored_searchable, :displayable, :facetable])
        t.object_type(:path=>"properties/object_type", :namespace_prefix=>nil, :index_as=>[:displayable, :facetable])
        t.depositor(:namespace_prefix=>nil, :index_as=>[:stored_searchable, :displayable, :facetable])
        t.metadata_md5(:namespace_prefix=>nil, :index_as=>[:stored_searchable])
        t.model_version(:path=>"properties/modelVersion", :namespace_prefix => nil)
        t.verified(:namespace_prefix=>nil, :index_as=>[:stored_searchable])
      end # set_terminology

      # Build the default XML document
      def self.xml_template
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.properties {
                 xml.status "draft"
                 xml.model_version DriDataModels::VERSION
            }
          end
          return builder.doc
      end

    end

  end

end
