module DRI
  module ModelSupport
  	module Files
      extend ActiveSupport::Concern
      require 'open-uri'
      require 'uri'
      require 'tempfile'

      included do
        around_save :ingest_files_if_changed
      end


      def process_ingest_of_file_urls
        self.dao_href.each do |url|
          if !url.blank?
            add_file_from_url url.strip
          end
        end
      end

      # Ingest a file from a given url
      def add_file_from_url file_url
        file_name = File.basename(URI(file_url).path)
        begin
          temp_file = Tempfile.new(['tmp', File.extname(file_url)])
          temp_file.binmode
          open(file_url) { |data| temp_file.write data.read}
          temp_file.close
          add_file temp_file, "content", file_name
          true
        rescue Exception => e
          logger.error "Error loading url: #{e.message}\n"
          logger.error e.backtrace.join("\n")
          false
        ensure
          temp_file.unlink
        end
      end

      # Ingest a file into a GenericFile and add it to the Batch object
      def add_file file, dsid="content",file_name
      end

      private


      def ingest_files_if_changed

        content_changed = false

        if (self.ingest_files_from_metadata == "true")
          content_changed = self.descMetadata.changed?
        end

        yield

        if content_changed && self.generic_files.empty? &&
            !self.dao_href.empty? && !new_record?
          Sufia.queue.push(IngestFilesFromMetadataJob.new(self.pid))
        end
      end
    end
  end
end