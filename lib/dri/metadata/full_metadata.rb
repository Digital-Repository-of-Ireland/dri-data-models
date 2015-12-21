# DRI
module DRI
  module Metadata
    # Implements a descMetadata datastream for holding the complete metadata XML
    # Mostly used for Digital objects that support the use of metadata wrapper terms
    # so the metadata can include a set of records rather than describing an individual object
    # @example MD wrappers can be:
    #   MODS: <mods:modsCollection> wrapper
    #   EAD: <ead:dsc> wrapper
    #   MARC <marc:collection> wrapper
    class FullMetadata < ActiveFedora::OmDatastream
    end
  end
end
