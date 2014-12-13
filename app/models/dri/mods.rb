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

    def self.find_or_create(pid)
      begin
        DRI::Mods.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
        DRI::Mods.create({pid: pid})
      end
    end
  end # class
end # module