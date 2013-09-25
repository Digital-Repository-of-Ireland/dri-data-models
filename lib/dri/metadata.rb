module DRI
  module Metadata
    autoload :Base, 'dri/metadata/base'
  	autoload :Descriptors, 'dri/metadata/descriptors'
    autoload :DublinCoreAudio, 'dri/metadata/dublin_core_audio'
    autoload :DublinCorePdfdoc, 'dri/metadata/dublin_core_pdfdoc'
    autoload :DublinCoreCollection, 'dri/metadata/dublin_core_collection'
    autoload :EncodedArchivalDescription, 'dri/metadata/encoded_archival_description'
    autoload :EncodedArchivalDescriptionComponent, 'dri/metadata/encoded_archival_description_component'
    autoload :MODS, 'dri/metadata/mods'
    autoload :Properties, 'dri/metadata/properties'
    autoload :QualifiedDublinCore, 'dri/metadata/qualified_dublin_core'
    autoload :Transformations, 'dri/metadata/transformations'
  end
end
