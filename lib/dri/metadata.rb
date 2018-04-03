module DRI
  module Metadata
    autoload :Base, 'dri/metadata/base'
    autoload :Descriptors, 'dri/metadata/descriptors'
    autoload :EncodedArchivalDescription, 'dri/metadata/encoded_archival_description'
    autoload :EncodedArchivalDescriptionComponent, 'dri/metadata/encoded_archival_description_component'
    autoload :FileProperties, 'dri/metadata/file_properties'
    autoload :FullMetadata, 'dri/metadata/full_metadata'
    autoload :Mods, 'dri/metadata/mods'
    autoload :Properties, 'dri/metadata/properties'
    autoload :Extracted, 'dri/metadata/extracted'
    autoload :QualifiedDublinCore, 'dri/metadata/qualified_dublin_core'
    autoload :Transformations, 'dri/metadata/transformations'
    autoload :SpatialTransformations, 'dri/metadata/transformations/spatial_transformations'
    autoload :Marc, 'dri/metadata/marc'
    autoload :LinkedData, 'dri/metadata/linked_data'
    autoload :Documentation, 'dri/metadata/documentation'
  end
end
