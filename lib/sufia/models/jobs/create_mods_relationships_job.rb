class CreateModsRelationshipsJob < ActiveFedoraPidBasedJob

  def queue_name
    :mods
  end

  def run
    sleep 3
    mods_object = DRI::Mods.find(self.pid)
    mods_object.process_mods_relationships
  end

end
