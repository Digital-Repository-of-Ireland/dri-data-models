# frozen_string_literal: true
# Implements a resque job to handle the ingest of EAD digital assets
# associated with EAD children components
class IngestFilesFromMetadataJob < IdBasedJob
  # Assign the resque queue name for this job
  def queue_name
    :ingest_files_from_metadata
  end

  # Run IngestFilesFromMetadataJob job
  def run
    object.process_ingest_of_file_urls
  end
end
