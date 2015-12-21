# Implements a resque job to handle the update/synchronisation
# of EAD parent components metadata when updating child component
class UpdateParentMetadataJob < ActiveFedoraIdBasedJob
  # Assign the resque queue name for this job
  def queue_name
    :update_parent_metadata
  end

  # Run UpdateParentMetadataJob job
  def run
    sleep 3
    object.descMetadata.update_parent_metadata(object.governing_collection, object.fullMetadata)
  end
end
