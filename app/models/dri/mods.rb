module DRI
  class Mods < DRI::Batch
    include DRI::ModelSupport::ModsSupport

    def initialize(args = {})
      args[:desc_metadata_class] = "DRI::Metadata::Mods"
      super(args)
    end

    def attributes=(properties)
      super(properties)
    end
  end
end