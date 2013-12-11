class SynchronizeMetadataJob < ActiveFedoraPidBasedJob

  def queue_name
    :synchronize_metadata
  end

  def run
    batch.synchronize_metadata
  end

end