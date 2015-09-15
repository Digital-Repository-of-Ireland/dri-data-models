class IngestFilesFromMetadataJob < ActiveFedoraIdBasedJob

  def queue_name
    :ingest_files_from_metadata
  end

  def run
    object.process_ingest_of_file_urls
  end

end