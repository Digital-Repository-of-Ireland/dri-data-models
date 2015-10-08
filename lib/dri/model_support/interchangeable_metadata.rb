module DRI
  module ModelSupport
    module InterchangeableMetadata
      extend ActiveSupport::Concern

      included do
        attr_accessor :desc_metadata_class

        # Descriptive metadata DS - F4 uses "File attachments" instead of DSs
        contains 'descMetadata', class_name: 'DRI::Metadata::Base'
        # Complete metadata record datastream
        contains 'fullMetadata', class_name: 'DRI::Metadata::FullMetadata'

        after_initialize :load_attributes

        # TODO: Check that these match the DRI Level 1 and 2 terms
        # DRI Mandatory (M)
        # Title (collection-level)
        property :title, delegate_to: 'descMetadata', multiple: true
        # Description (collection-level)
        property :description, delegate_to: 'descMetadata', multiple: true
        # ADDED TYPE, it is compulsory
        # property :type, delegate_to: 'descMetadata', multiple: true
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
        @desc_metadata_class = desc_metadata_class if self.new?
      end

      private

      def custom_validations
        return true unless descMetadata.class < DRI::Metadata::Base

        results = descMetadata.custom_validations
        return true if results.empty?

        results.each { |key, value| errors.add(key, value) }

        false
      end # custom_validations

      def get_metadata_class_from_xml(xml_text)
        result = nil
        ead_components = %w(c c01 c02 c03 c04 c05 c06 c07 c08 c09 c10 c11 c12)
        marc_components = %w(collection record)

        if xml_text.is_a? Nokogiri::XML::Document
          xml = xml_text
        else
          xml = Nokogiri::XML xml_text
        end

        namespace = xml.namespaces
        root_name = xml.root.name

        if namespace.value?('http://purl.org/dc/elements/1.1/')
          result = 'DRI::Metadata::QualifiedDublinCore'
        elsif namespace.value?('http://www.loc.gov/mods/v3')
          result = 'DRI::Metadata::Mods'
        elsif namespace.value?('http://www.loc.gov/MARC21/slim')
          result = 'DRI::Metadata::Marc'
        elsif (xml.internal_subset.present? && xml.internal_subset.name == 'ead') || root_name == 'ead'
          result = 'DRI::Metadata::EncodedArchivalDescription'
        elsif ead_components.include? root_name
          result = 'DRI::Metadata::EncodedArchivalDescriptionComponent'
        elsif marc_components.include? root_name
          result = 'DRI::Metadata::Marc'
        elsif root_name == 'mods'
          result = 'DRI::Metadata::Mods'
        end

        result
      end # get_metadata_class_from_xml

      def load_attributes
        ead_classes = %w(DRI::Metadata::EncodedArchivalDescription
                         DRI::Metadata::EncodedArchivalDescriptionComponent)
        ds = nil

        if new_record? && !desc_metadata_class.nil?
          # For new objects, check what metadata class was asked for during initialization
          ds_class = @desc_metadata_class.to_s

          if ead_classes.include? ds_class
            ds = ds_class.constantize.new
          else
            # Load class from :desc_metadata_class which is set ingest_controller
            if ead_classes.include? desc_metadata_class
              ds = desc_metadata_class.constantize.new
            else
              # if NOT EAD or EADComponent, do not create DS
              return
            end
          end
        end

        return if ds.nil?

        ds.instance_variable_set(:@dsid, 'descMetadata')
        attach_file(ds, 'descMetadata')
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
