# frozen_string_literal: true
# Implements a resque job to handle the update/re-index of solr fields for a given
# digital object
class UpdateIndexJob < IdBasedJob
  # Assign the resque queue name for this job
  def queue_name
    :update_index
  end

  # Run UpdateIndexJob job
  def run
    raise "No object found for id: #{id}" if object.nil?
    object.update_index
  end
end
