# frozen_string_literal: true
# Implements a resque job to handle the creation of MARC records
class CreateMarcRecordsJob < IdBasedJob
  # Assign the resque queue name for this job
  def queue_name
    :marc
  end

  # Run CreateMarcRecordsJob job
  def run
    sleep 3
    marc_object = DRI::Identifier.retrieve_object(pid)
    marc_object.create_marc_records
  end
end
