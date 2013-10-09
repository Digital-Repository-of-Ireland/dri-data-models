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
        validates :description, :presence => true
        validates :rights, :presence => true, :if => :require_rights?
        validates :type, :presence => true, :if => :require_type?
        validates :ead_level, :presence => true, :if => :require_ead_level?
      end

      def roles= roles
        if descMetadata.class == DRI::Metadata::QualifiedDublinCore
          descMetadata.roles = roles
        end
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

        curr_metadata = descMetadata.class.to_s
        replacing_metadata = get_metadata_class_from_xml xml_text

        if curr_metadata == replacing_metadata
          descMetadata.ng_xml = xml_text
          return true
        elsif replacing_metadata != nil
          ds = replacing_metadata.constantize.from_xml xml_text

          # Given that the original and replacing metadata are definitely
          # using different metadata schema, do any of them disallow
          # being interchanged.
          if !ds.interchangeable? || !descMetadata.interchangeable?
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
          # more rights, but as long as we validate the EAD collection for
          # the presence of rights, then the EAD component is automatically valid.
          if descMetadata.is_a?(DRI::Metadata::EncodedArchivalDescriptionComponent)
            false
          else
            true
          end
      end

      def require_type?
        # Only required at item level in EAD
        if descMetadata.is_a?(DRI::Metadata::EncodedArchivalDescription)
          false
        elsif descMetadata.is_a?(DRI::Metadata::EncodedArchivalDescriptionComponent)
          if ead_level == "item"
            true
          else
            false
          end
        else
          true
        end
      end

      def require_ead_level?
        descMetadata.is_a? DRI::Metadata::EncodedArchivalDescriptionComponent
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
        root_name = xml.root.name

        if namespace.has_value?("http://purl.org/dc/elements/1.1/")
          result = "DRI::Metadata::QualifiedDublinCore"
        elsif namespace.has_value?("http://www.loc.gov/mods/v3")
          result = "DRI::Metadata::MODS"
        elsif xml.internal_subset != nil && xml.internal_subset.name == 'ead'
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
        ds_class = ""
        ds = nil

        if (new? && desc_metadata_class != nil)
          # For new objects, check what metadata class was asked for during initialization
          ds_class = @desc_metadata_class.to_s

          if ["DRI::Metadata::QualifiedDublinCore", "DRI::Metadata::MODS",
                 "DRI::Metadata::EncodedArchivalDescription", 
                 "DRI::Metadata::EncodedArchivalDescriptionComponent"].include? ds_class
            ds = ds_class.constantize.new
          else
            ds = DRI::Metadata::QualifiedDublinCore.new
          end
        else
          # When loading the object from Fedora, check what metadata
          # the XML uses and load the correct class.
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

        @metadata_class = descMetadata.class

        if descMetadata.class < DRI::Metadata::Base
          descMetadata.set_delegates self
        end
      end

      # Indexing object types as a hierarchical tree
      def object_types_to_solr(solr_doc=Hash.new)

        # Add title metadata from parent collections
        object_types = []

        if require_type?
          main_category = nil

          type.each do | curr_category |
            if DRI::Vocabulary::dcmiType.include? curr_category
                object_types.push curr_category
                main_category = curr_category
            else
              if main_category != nil
                object_types.push main_category+":"+curr_category
              end
            end
          end
        else
          case descMetadata
          when DRI::Metadata::EncodedArchivalDescriptionComponent
            object_types.push ead_level
          when DRI::Metadata::EncodedArchivalDescription
            object_types.push "Collection"
          end
        end

        if object_types.count > 0
          solr_doc.merge!(solr_name('object_type', :facetable) => object_types)
        end

        solr_doc
      end

    end
  end
end