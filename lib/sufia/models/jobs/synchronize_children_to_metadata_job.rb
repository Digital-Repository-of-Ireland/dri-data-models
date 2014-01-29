class SynchronizeChildrenToMetadataJob < ActiveFedoraPidBasedJob

  def queue_name
    :synchronize_children_to_metadata
  end

  def run
    batch.synchronize_children_to_metadata
  end

end