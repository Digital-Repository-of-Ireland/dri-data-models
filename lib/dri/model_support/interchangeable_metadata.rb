module DRI
  module ModelSupport
    module InterchangeableMetadata
      extend ActiveSupport::Concern

      included do
        attr_accessor :desc_metadata_class

        # Descriptive metadata datastream - F4 uses "File attachments" instead of datas
        contains 'descMetadata', class_name: 'DRI::Metadata::Base'
        # Complete metadata record datastream
        contains 'fullMetadata', class_name: 'DRI::Metadata::FullMetadata'

        after_initialize :load_attributes

        # TODO Check that these match the DRI Level 1 and 2 terms (some are missing)
        # DRI Mandatory (M)
        # Title (collection-level)
        property :title, delegate_to: 'descMetadata', multiple: true
        # Description (collection-level)
        property :description, delegate_to: 'descMetadata', multiple: true
        # ADDED TYPE, it is compulsory
        #property :type, delegate_to: 'descMetadata', multiple: true
        # Rights (collection-level)
        property :rights, delegate_to: 'descMetadata', multiple: true
        # Creator (collection-level)
        property :creator, delegate_to: 'descMetadata', multiple: true

        # DRI Recommended (R)
        # Contributor
        property :contributor, delegate_to: 'descMetadata', multiple: true
        # Publisher (collection-level, DRI pre-populated)
        property :publisher, delegate_to: 'descMetadata', multiple: true
        # Published Date (collection-level)
        property :published_date, delegate_to: 'descMetadata', multiple: true
        # Creation Date (collection-level, DRI pre-populated)
        property :creation_date, delegate_to: 'descMetadata', multiple: true
        # Subject (collection-level)
        property :subject, delegate_to: 'descMetadata', multiple: true
        # Language (collection-level)
        property :language, delegate_to: 'descMetadata', multiple: true

        validate :custom_validations
      end

      # Should only be set in a new class
      def desc_metadata_class=(desc_metadata_class)
        if self.new?
          @desc_metadata_class = desc_metadata_class
        end
      end

      private

      def custom_validations
        if descMetadata.class < DRI::Metadata::Base
          results = descMetadata.custom_validations

          if results.empty?
            return true
          else
            results.each do |key, value|
              errors.add(key, value)
            end
            return false
          end
        else
          return true
        end
      end # custom_validations

      def get_metadata_class_from_xml(xml_text)
        result = nil
        xml = nil

        if xml_text.is_a? Nokogiri::XML::Document
          xml = xml_text
        else
          xml = Nokogiri::XML xml_text
        end

        namespace = xml.namespaces
        root_name = xml.root.name

        if namespace.has_value?('http://purl.org/dc/elements/1.1/')
          result = 'DRI::Metadata::QualifiedDublinCore'
        elsif namespace.has_value?('http://www.loc.gov/mods/v3')
          result = 'DRI::Metadata::Mods'
        elsif namespace.has_value?('http://www.loc.gov/MARC21/slim')
          result = 'DRI::Metadata::Marc'
        elsif (xml.internal_subset != nil && xml.internal_subset.name == 'ead') || ['ead'].include?(root_name)
          result = 'DRI::Metadata::EncodedArchivalDescription'
        elsif ['c', 'c01', 'c02', 'c03', 'c04', 'c05', 'c06', 'c07', 'c08', 'c09', 'c10', 'c11', 'c12'].include? root_name
          result = 'DRI::Metadata::EncodedArchivalDescriptionComponent'
        elsif ['collection', 'record'].include? root_name
          result = 'DRI::Metadata::Marc'
        elsif ['mods'].include?(root_name)
          result = 'DRI::Metadata::Mods'
        end

        return result
      end # get_metadata_class_from_xml

      def load_attributes
        ds_class = ""
        ds = nil

        if new_record? && !desc_metadata_class.nil?
          # For new objects, check what metadata class was asked for during initialization
          ds_class = @desc_metadata_class.to_s

          if ['DRI::Metadata::EncodedArchivalDescription',
              'DRI::Metadata::EncodedArchivalDescriptionComponent'].include? ds_class
            ds = ds_class.constantize.new
          else
            # Load class from :desc_metadata_class which is set ingest_controller
            if ['DRI::Metadata::EncodedArchivalDescription',
                'DRI::Metadata::EncodedArchivalDescriptionComponent'].include? desc_metadata_class
              ds = desc_metadata_class.constantize.new
            else
              # if EAD or EADComponent do not create ds
              return
            end
          end
        end

        if (ds != nil)
          ds.instance_variable_set(:@dsid, 'descMetadata')
          self.attach_file(ds, 'descMetadata')
        end
      end # load_attributes

      def load_attached_files
        super
      
        attach_desc_metadata
      end

      def attach_desc_metadata
        ds_class = get_metadata_class_from_xml(descMetadata.to_xml)

        return unless %w(DRI::Metadata::EncodedArchivalDescription 
                         DRI::Metadata::EncodedArchivalDescriptionComponent).include? ds_class

        old_digital_object = descMetadata.uri
        ds = ds_class.constantize.from_xml(descMetadata.to_xml)
        ds.uri = old_digital_object
          
        ds.instance_variable_set(:@dsid, 'descMetadata')
        attached_files[:descMetadata] = ds
      end

    end # module
  end # module
end # module
