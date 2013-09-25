module DRI
  module ModelSupport
  	module InterchangeableMetadata
      extend ActiveSupport::Concern
    
      included do
        attr_accessor :metadata_class
        attr_accessor :desc_metadata_class

        has_metadata :name => "descMetadata", :type => ActiveFedora::OmDatastream

        after_initialize :load_delegates
      end

      def has_metadata_class_changed?
        if (self.metadata_class != descMetadata.class)
          true
        else
          false
        end
      end

      # Use this in preference over the setting xml directly in the OmDatastreams
      def update_metadata xml_text
        if (xml_text.is_a? File)
          xml_text = xml_text.read
        end

        if !descMetadata.is_interchangeable?
         return false
        end

        curr_metadata = descMetadata.class.to_s
        replacing_metadata = get_metadata_class_from_xml xml_text

        if curr_metadata == replacing_metadata
          descMetadata.from_xml xml_text
          return true
        else
          ds = replacing_metadata.constantize.from_xml xml_text

          if (!ds.is_interchangeable?)
            return false
          end

          if descMetadata.class < DRI::Metadata::Base
            descMetadata.unset_delegates.each do |x|
              self.class.delegates.delete(x)
              self.class.send :remove_method, x.to_sym
              self.class.send :remove_method, "#{x}=".to_sym
            end              
          end

          ds.instance_variable_set :@dsid, "descMetadata"
          self.add_datastream ds

          if descMetadata.class < DRI::Metadata::Base
            descMetadata.set_delegates self
          end

          return true
        end
      end

      private

      def get_metadata_class_from_xml xml_text
        result = "ActiveFedora::OmDatastream"
        xml = nil

        if (xml_text.is_a? Nokogiri::XML)
          xml = xml_text
        else
          xml = Nokogiri::XML xml_text
        end

        namespace = xml.namespaces

        if namespace.has_value?("http://purl.org/dc/elements/1.1/")
          result = "DRI::Metadata::QualifiedDublinCore"
        elsif namespace.has_value?("http://www.loc.gov/mods/v3")
          result = "DRI::Metadata::MODS"
        end

        #if xml.internal_subset.name == 'ead'
        #  result = "DRI::Metadata::EncodedArchivalDescription"
        #end

        root_name = xml.root.name

        if ['ead'].include? root_name
          result = "DRI::Metadata::EncodedArchivalDescription"
        elsif ['c', 'c1', 'c2', 'c3', 'c4', 'c5', 'c6', 'c7', 'c8', 'c9', 'c10', 'c11', 'c12'].include? root_name
          result = "DRI::Metadata::EncodedArchivalDescriptionComponent"
        end        

        return result
      end

      def load_delegates
        if datastreams.has_key?("descMetadata")
    
        # If descMetadata is an OmDatastream, then check if we need to replace it with a DRI
        # metadata class
        if descMetadata.class == ActiveFedora::OmDatastream
          ds_class = ""
          ds = nil

          if (desc_metadata_class != nil)
            ds_class = desc_metadata_class.to_s
            if ds_class == "DRI::Metadata::QualifiedDublinCore"
              ds = DRI::Metadata::QualifiedDublinCore.new
            elsif ds_class == "DRI::Metadata::MODS"
              ds = DRI::Metadata::MODS.new
            elsif ds_class == "DRI::Metadata::EncodedArchivalDescription"
              ds = DRI::Metadata::EncodedArchivalDescription.new
            elsif ds_class == "DRI::Metadata::EncodedArchivalDescriptionComponent"
              ds = DRI::Metadata::EncodedArchivalDescriptionComponent.new
            end
          else
            ds_class = get_metadata_class_from_xml descMetadata.to_xml
            if ds_class == "ActiveFedora::OmDatastream"
              ds = DRI::Metadata::QualifiedDublinCore.new
            elsif ds_class == "DRI::Metadata::QualifiedDublinCore"
              ds = DRI::Metadata::QualifiedDublinCore.from_xml descMetadata.to_xml
            elsif ds_class == "DRI::Metadata::MODS"
              ds = DRI::Metadata::MODS.from_xml descMetadata.to_xml
            elsif ds_class == "DRI::Metadata::EncodedArchivalDescription"
              ds = DRI::Metadata::EncodedArchivalDescription.from_xml descMetadata.to_xml
            elsif ds_class == "DRI::Metadata::EncodedArchivalDescriptionComponent"
              ds = DRI::Metadata::EncodedArchivalDescriptionComponent.from_xml descMetadata.to_xml
            end
          end

          if (ds != nil)            
            ds.instance_variable_set :@dsid, "descMetadata"
            self.add_datastream ds
          end
        end

        self.metadata_class = descMetadata.class

        if descMetadata.class < DRI::Metadata::Base
          descMetadata.set_delegates self
        end
      end
      end
    end
  end
end