# frozen_string_literal: true
# Implements a resque job to handle the creation of EAD children components
class SynchronizeChildrenToMetadataJob < IdBasedJob
  # Assign the resque queue name for this job
  def queue_name
    :synchronize_children_to_metadata
  end

  # Run SynchronizeChildrenToMetadataJob job
  def run
    sleep 3
    object.synchronize_children_to_metadata
  end
end
