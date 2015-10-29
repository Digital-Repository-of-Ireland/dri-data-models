class UpdateIndexJob < ActiveFedoraIdBasedJob

  def queue_name
    :update_index
  end

  def run
    object.update_index
  end

end