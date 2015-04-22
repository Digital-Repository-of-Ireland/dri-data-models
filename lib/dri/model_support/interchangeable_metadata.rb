module DRI
  module ModelSupport
    module InterchangeableMetadata
      extend ActiveSupport::Concern

      included do
        attr_accessor :desc_metadata_class
        attr_accessor :trigger_update

        # Descriptive metadata datastream
        contains "descMetadata", class_name: "DRI::Metadata::Base"
        # Complete metadata record datastream
        contains "fullMetadata", class_name: "DRI::Metadata::FullMetadata"

        after_initialize :load_attributes
        after_save :reset_metadata_check

        # TODO Check that these match the DRI Level 1 and 2 terms (some are missing)
        # DRI Mandatory (M)
        # Title (collection-level)
        has_attributes :title, datastream: :descMetadata, multiple: true
        # Description (collection-level)
        has_attributes :description, datastream: :descMetadata, multiple: true
        # ADDED TYPE, it is compulsory
        has_attributes :type, datastream: :descMetadata, multiple: true
        # Rights (collection-level)
        has_attributes :rights, datastream: :descMetadata, multiple: true
        # Creator (collection-level)
        has_attributes :creator, datastream: :descMetadata, multiple: true

        # DRI Recommended (R)
        # Contributor
        has_attributes :contributor, datastream: :descMetadata, multiple: true
        # Publisher (collection-level, DRI pre-populated)
        has_attributes :publisher, datastream: :descMetadata, multiple: true
        # Published Date (collection-level)
        has_attributes :published_date, datastream: :descMetadata, multiple: true
        # Creation Date (collection-level, DRI pre-populated)
        has_attributes :creation_date, datastream: :descMetadata, multiple: true
        # Subject (collection-level)
        has_attributes :subject, datastream: :descMetadata, multiple: true
        # Language (collection-level)
        has_attributes :language, datastream: :descMetadata, multiple: true

        # FIXME - check DRI elements below, not included here initially
        # Source (collection-level, R)
        # has_attributes :source, datastream: :descMetadata, multiple: true
        # Geographical coverage (collection-level)
        # has_attributes :geographical_coverage, datastream: :descMetadata, multiple: true
        # Temporal coverage (collection-level)
        # has_attributes :temporal_coverage, datastream: :descMetadata, multiple: true

        validate :custom_validations
      end

      def has_metadata_class_changed?
        (@metadata_class != descMetadata.class) ? true : false
      end

      # Should only be set in a new class
      def desc_metadata_class= desc_metadata_class
        if self.new?
          @desc_metadata_class = desc_metadata_class
        end
      end

      # Issue 1195 - Trigger update, additional flag to avoid ead updates when loading fedora objects
      # load_attributes changes the descMetadata datastream to load the right metadata class
      def trigger_update= update
        @trigger_update = update
      end

      def trigger_update
        @trigger_update || false
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
      end # custom_validations

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
          result = "DRI::Metadata::Mods"
          # result = (!xml.xpath("/mods:mods/mods:typeOfResource[@collection='yes']").empty?) ? "DRI::Metadata::ModsCollection" : "DRI::Metadata::Mods"
        elsif namespace.has_value?("http://www.loc.gov/MARC21/slim")
          result = "DRI::Metadata::Marc"
        elsif (xml.internal_subset != nil && xml.internal_subset.name == 'ead') || ['ead'].include?(root_name)
          result = "DRI::Metadata::EncodedArchivalDescription"
        elsif ['c', 'c01', 'c02', 'c03', 'c04', 'c05', 'c06', 'c07', 'c08', 'c09', 'c10', 'c11', 'c12'].include? root_name
          result = "DRI::Metadata::EncodedArchivalDescriptionComponent"
        elsif ['collection', 'record'].include? root_name
          result = "DRI::Metadata::Marc"
        elsif ['mods'].include?(root_name)
          result = "DRI::Metadata::Mods"
        #elsif ['modsCollection'].include?(root_name)
          # Check whether the first record is a collection
        #  result = (!xml.xpath("/modsCollection/mods[1]/typeOfResource[@collection='yes']").empty?) ? "DRI::Metadata::ModsCollection" : "DRI::Metadata::Mods"
        end

        return result
      end # get_metadata_class_from_xml

      def reset_metadata_check
        @metadata_class = descMetadata.class
      end

      def load_attributes
        ds_class = ""
        ds = nil

        if (new_record? && desc_metadata_class != nil)
          # For new objects, check what metadata class was asked for during initialization
          ds_class = @desc_metadata_class.to_s

          if ["DRI::Metadata::QualifiedDublinCore",
              "DRI::Metadata::Mods",
              "DRI::Metadata::EncodedArchivalDescription",
              "DRI::Metadata::EncodedArchivalDescriptionComponent",
              "DRI::Metadata::Marc"].include? ds_class
            ds = ds_class.constantize.new
          else
            # Load class from :desc_metadata_class which is set ingest_controller
            ds = desc_metadata_class.constantize.new
          end
        else
          # When loading the object from Fedora, check what metadata
          # the XML uses and load the correct class.
          ds_class = get_metadata_class_from_xml descMetadata.to_xml
          
          old_digital_object = descMetadata.uri
          unless (ds_class == nil)
            ds = ds_class.constantize.from_xml descMetadata.to_xml
          else
            ds = DRI::Metadata::QualifiedDublinCore.new
          end
          ds.uri = old_digital_object
        end

        if (ds != nil)
          ds.instance_variable_set :@dsid, "descMetadata"
          self.attach_file ds, "descMetadata"
        end
        @metadata_class = descMetadata.class
        # FIXME Check whether desc_metadata_class has to be set here as well
        # This is causing problems when updating EAD descMetadata datastream as desc_metadata_class is nil when
        # loading an existing EAD object
        #@desc_metadata_class = descMetadata.class
        # VERY IMPORTANT!! issue1195 Fix to Avoid descMetadata.changed? = true when loading objects from fedora
        # self.descMetadata.save if self.descMetadata.changed?

      end # load_attributes
    end # module
  end # module
end # module
