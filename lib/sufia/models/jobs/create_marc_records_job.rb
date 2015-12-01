# Implements a resque job to handle the creation of MARC records
class CreateMarcRecordsJob < ActiveFedoraIdBasedJob
  def queue_name
    :marc
  end

  def run
    sleep 3
    marc_object = DRI::Marc.find(self.pid)
    marc_object.create_marc_records
  end
end
