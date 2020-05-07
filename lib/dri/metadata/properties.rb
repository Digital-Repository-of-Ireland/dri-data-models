# DRI namespace
module DRI
  # Metadata namespace
  module Metadata
    # Implements descMetadata DRI properties for DRI metadata digital objects
    # Common to all supported metadata standards (MODS, EAD, MARC and QDC)
    class Properties < DRI::Datastreams::OmDatastream
      include DRI::Metadata
      extend DRI::Metadata::Terminologies::Properties

      def synchronize_metadata_on_save
        false
      end

      # Build the default XML document
      def self.xml_template
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.properties {
            xml.model_version DriDataModels::VERSION
            xml.status 'draft'
          }
        end

        builder.doc
      end

      # Determine whether the metadata describes a collection
      # @return [Boolean] true if metadata specified this is a collection; false otherwise
      def collection?
        object_type.include? 'Collection'
      end

      load_inherited_terminology
    end
  end
end
