class UpdateParentMetadataJob < ActiveFedoraIdBasedJob

  def queue_name
    :update_parent_metadata
  end

  def run
    sleep 3
    object.descMetadata.update_parent_metadata(object.governing_collection, object.fullMetadata)
  end

end