# Implements a resque job to handle the creation of EAD children components
class SynchronizeChildrenToMetadataJob < ActiveFedoraIdBasedJob
  def queue_name
    :synchronize_children_to_metadata
  end

  def run
    sleep 3
    object.synchronize_children_to_metadata
  end
end
