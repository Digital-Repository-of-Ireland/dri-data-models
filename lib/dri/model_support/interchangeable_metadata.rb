module DRI
  module ModelSupport
  	module InterchangeableMetadata
      extend ActiveSupport::Concern
    
      included do
        attr_accessor :desc_metadata_class

        has_metadata :name => "descMetadata", :type => ActiveFedora::OmDatastream

        after_initialize :load_delegates
        after_save :reset_metadata_check

        validates :title, :presence => true
        validates :rights, :presence => true, :if => :require_rights?
      end

      def has_metadata_class_changed?
        if (@metadata_class != descMetadata.class)
          true
        else
          false
        end
      end

      # Should only be set in a new class
      def desc_metadata_class= desc_metadata_class
        if self.new?
          @desc_metadata_class = desc_metadata_class
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
          descMetadata.ng_xml = xml_text
          return true
        else
          ds = replacing_metadata.constantize.from_xml xml_text

          if (!ds.is_interchangeable?)
            return false
          end

          # Got to delete the old delegates and their methods
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

      @metadata_class

      def require_rights?
          # An EAD component inherits the rights of the EAD collection. It can add
          # morerights, but as long as we validate the EAD collection for
          # the presence of rights, then the EAD component is automatically valid.
          if descMetadata.is_a?(DRI::Metadata::EncodedArchivalDescriptionComponent)
            false
          else
            true
          end
      end

      def get_metadata_class_from_xml xml_text
        result = nil
        xml = nil

        if (xml_text.is_a? Nokogiri::XML::Document)
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

      def reset_metadata_check
        @metadata_class = descMetadata.class
      end

      def load_delegates
        if datastreams.has_key?("descMetadata")
    
        # If descMetadata is an OmDatastream, then check if we need to replace it with a DRI
        # metadata class
        if descMetadata.class == ActiveFedora::OmDatastream
          ds_class = ""
          ds = nil

          if (desc_metadata_class != nil)
            ds_class = @desc_metadata_class.to_s

            if ["DRI::Metadata::QualifiedDublinCore", "DRI::Metadata::MODS",
                 "DRI::Metadata::EncodedArchivalDescription", 
                 "DRI::Metadata::EncodedArchivalDescriptionComponent"].include? ds_class
              ds = ds_class.constantize.new
            else
              ds = DRI::Metadata::QualifiedDublinCore.new
            end
          else
            ds_class = get_metadata_class_from_xml descMetadata.to_xml

            unless (ds_class == nil)
              ds = ds_class.constantize.from_xml descMetadata.to_xml
            else
              ds = DRI::Metadata::QualifiedDublinCore.new
            end
          end

          if (ds != nil)            
            ds.instance_variable_set :@dsid, "descMetadata"
            self.add_datastream ds
          end
        end

        @metadata_class = descMetadata.class

        if descMetadata.class < DRI::Metadata::Base
          descMetadata.set_delegates self
        end
      end
      end
    end
  end
end