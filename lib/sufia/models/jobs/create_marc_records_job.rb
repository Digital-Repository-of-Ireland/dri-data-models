# Implements a resque job to handle the creation of MARC records
class CreateMarcRecordsJob < ActiveFedoraIdBasedJob
  # Assign the resque queue name for this job
  def queue_name
    :marc
  end

  # Run CreateMarcRecordsJob job
  def run
    sleep 3
    marc_object = DRI::Marc.find(self.pid)
    marc_object.create_marc_records
  end
end
