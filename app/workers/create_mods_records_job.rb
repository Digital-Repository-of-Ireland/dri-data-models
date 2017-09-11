# Implements a resque job to handle the creation of MARC records
class CreateModsRecordsJob < ActiveFedoraIdBasedJob
  # Assign the resque queue name for this job
  def queue_name
    :mods
  end

  # Run CreateModsRecordsJob job
  def run
    sleep 3
    mods_object = DRI::Identifier.retrieve_object(self.pid)
    mods_object.create_mods_records
  end
end
