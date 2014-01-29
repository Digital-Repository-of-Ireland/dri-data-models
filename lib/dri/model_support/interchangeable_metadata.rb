module DRI
  module ModelSupport
  	module InterchangeableMetadata
      extend ActiveSupport::Concern
    
      included do
        attr_accessor :desc_metadata_class

        has_metadata :name => "descMetadata", :type => ActiveFedora::OmDatastream

        after_initialize :load_attributes
        after_save :reset_metadata_check, :synchronize_if_changed

        has_attributes :title, datastream: :descMetadata, multiple: true
        has_attributes :description, datastream: :descMetadata, multiple: true
        has_attributes :language, datastream: :descMetadata, multiple: true
        has_attributes :creator, datastream: :descMetadata, multiple: true
        has_attributes :contributor, datastream: :descMetadata, multiple: true
        has_attributes :publisher, datastream: :descMetadata, multiple: true
        has_attributes :date, datastream: :descMetadata, multiple: true
        has_attributes :published_date, datastream: :descMetadata, multiple: true
        has_attributes :creation_date, datastream: :descMetadata, multiple: true
        has_attributes :relation, datastream: :descMetadata, multiple: true
        has_attributes :subject, datastream: :descMetadata, multiple: true
        has_attributes :source, datastream: :descMetadata, multiple: true
        has_attributes :geographical_coverage, datastream: :descMetadata, multiple: true
        has_attributes :temporal_coverage, datastream: :descMetadata, multiple: true
        has_attributes :rights, datastream: :descMetadata, multiple: true
        has_attributes :type, datastream: :descMetadata, multiple: true
        has_attributes :format, datastream: :descMetadata, multiple: true
        has_attributes :coverage, datastream: :descMetadata, multiple: true
        has_attributes :identifier, datastream: :descMetadata, multiple: true
        has_attributes :geocode_point, datastream: :descMetadata, multiple: true
        has_attributes :geocode_box, datastream: :descMetadata, multiple: true
        has_attributes  *(DRI::Vocabulary::marcRelators.map { |s| s.prepend("role_").to_sym}), datastream: :descMetadata,
                                    multiple: true

        has_attributes :abstract, datastream: :descMetadata, multiple: false
        has_attributes :bioghist, datastream: :descMetadata, multiple: false
        has_attributes :scope_content, datastream: :descMetadata, multiple: false
        has_attributes :ead_level, datastream: :descMetadata, multiple: false
        has_attributes :name_coverage, datastream: :descMetadata, multiple: true
        has_attributes :physdesc, datastream: :descMetadata, multiple: true
        has_attributes :dao, datastream: :descMetadata, multiple: true
        has_attributes :unitid, datastream: :descMetadata, multiple: false
        has_attributes :repository_code, datastream: :descMetadata, multiple: false
        has_attributes :country_code, datastream: :descMetadata, multiple: false
        has_attributes :identifier, datastream: :descMetadata, multiple: false

        validate :custom_validations
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
          old_digital_object = descMetadata.digital_object
          ds = replacing_metadata.constantize.from_xml xml_text

          # Given that the original and replacing metadata are definitely
          # using different metadata schema, do any of them disallow
          # being interchanged.
          if !ds.interchangeable? || !descMetadata.interchangeable?
            return false
          end

          ds.digital_object = old_digital_object
          ds.instance_variable_set :@dsid, "descMetadata"
          self.add_datastream ds

          return true
        end
      end

      def synchronize_metadata
        if descMetadata.class == DRI::Metadata::EncodedArchivalDescription
          descMetadata.sync_children_to_metadata pid, depositor
        end
        #descMetadata.synchronize_metadata governing_collection
      end

      private

      @metadata_class


      def custom_validations
        if descMetadata.class < DRI::Metadata::Base
          results = descMetadata.custom_validations

          if results.empty?
            return true
          else
            results.each do |key, value|
              errors.add(key,value)
            end
            return false
          end
        else
          return true
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

      def load_attributes
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
          old_digital_object = descMetadata.digital_object
          unless (ds_class == nil)
            ds = ds_class.constantize.from_xml descMetadata.to_xml
          else
            ds = DRI::Metadata::QualifiedDublinCore.new
          end
          ds.digital_object = old_digital_object
        end

        if (ds != nil)       
          ds.instance_variable_set :@dsid, "descMetadata"
          self.add_datastream ds
        end

        @metadata_class = descMetadata.class
      end

      def synchronize_if_changed
        if (self.descMetadata.synchronize_metadata_on_save == true)
          content_changed = self.descMetadata.changed?
          yield
          Sufia.queue.push(SynchronizeMetadata.new(self.pid)) if content_changed
        end
      end

      # Indexing object types as a hierarchical tree
      def object_types_to_solr(solr_doc=Hash.new)

        # Add title metadata from parent collections
        object_types = []

        if self.respond_to? type
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