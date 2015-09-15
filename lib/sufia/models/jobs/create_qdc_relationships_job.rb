class CreateQdcRelationshipsJob < ActiveFedoraIdBasedJob

  def queue_name
    :relationships
  end

  def run
    sleep 3
    object = DRI::QualifiedDublinCore.find(self.pid)
    object.process_collection_relationships
  end

end
