# DRI namespace
module DRI
  # Metadata namespace
  module Metadata
    # Implements descMetadata DRI properties for DRI metadata digital objects
    # Common to all supported metadata standards (MODS, EAD, MARC and QDC)
    class Properties < DRI::Datastreams::OmDatastream
      include DRI::Metadata

      def synchronize_metadata_on_save
        false
      end

      # OM (Opinionated Metadata) terminology mapping
      def self.load_inherited_terminology
        set_terminology do |t|
          # Selects the root node of the XML document
          t.root(path: 'properties', xmlns: '', namespace_prefix: nil)
          t.status(namespace_prefix: nil, index_as: [:symbol, :stored_searchable, :displayable, :facetable])
          t.object_type(namespace_prefix: nil, path: 'objectType', index_as: [:displayable, :facetable])
          t.depositor(namespace_prefix: nil, index_as: [:stored_searchable, :displayable, :facetable])
          t.metadata_md5(namespace_prefix: nil, index_as: [:stored_searchable])
          t.model_version(namespace_prefix: nil, path: 'model_version')
          t.doi(namespace_prefix: nil, index_as: [:stored_searchable, :displayable])
          t.cover_image(namespace_prefix: nil, index_as: [:stored_searchable, :displayable])
          t.institute(namespace_prefix: nil, index_as: [:stored_searchable, :displayable, :facetable])
          t.depositing_institute(namespace_prefix: nil, index_as: [:stored_searchable, :displayable])
          t.licence(namespace_prefix: nil, index_as: [:stored_searchable, :displayable, :facetable])
          t.master_file_access(namespace_prefix: nil, index_as: [:stored_searchable, :facetable])
          t.published_at(namespace_prefix: nil, index_as: [:stored_searchable])
        end # set_terminology
      end

      # Build the default XML document
      def self.xml_template
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.properties {
            xml.status 'draft'
            xml.model_version DriDataModels::VERSION
            xml.object_version 1
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
