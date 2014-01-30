class SynchronizeChildrenToMetadataJob < ActiveFedoraPidBasedJob

  def queue_name
    :synchronize_children_to_metadata
  end

  def run
    object.synchronize_children_to_metadata
  end

end