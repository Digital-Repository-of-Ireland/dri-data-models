# Implements a resque job to handle the update/re-index of solr fields for a given
# digital object
class UpdateIndexJob < ActiveFedoraIdBasedJob
  def queue_name
    :update_index
  end

  def run
    object.update_index
  end
end
