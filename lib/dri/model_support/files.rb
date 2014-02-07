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

      def file_metadata_to_solr(solr_doc=Hash.new)
        file_type = []
        file_type_display = []

        if is_collection?
          file_type.push "collection"

          if !is_root_collection? && !ead_level.blank?
            file_type_display.push ead_level.strip.capitalise
          else
            file_type_display.push "Collection"
          end
        end

        solr_query = "is_part_of_ssim:info:fedora/#{id}"
        results = ActiveFedora::SolrService.query(solr_query, :defType => "edismax")

        if results != nil
          results.each do |gf|
            if !is_collection? && gf.key?(solr_name('file_type', :stored_searchable))
              file_type = file_type | gf[solr_name('file_type', :stored_searchable)[0]]
              file_type_display = file_type_display | gf[solr_name('file_type', :stored_searchable)[0]].capitalise
            end
          end
        end

        if file_type.empty?
          file_type.push "unknown"
          file_type_display.push "Unknown"
        end

        solr_doc.merge!(solr_name('file_type', :stored_searchable) => file_type)
        solr_doc.merge!(solr_name('file_type', :facetable) => file_type)
        solr_doc.merge!(solr_name('file_type_display', :stored_searchable) => file_type_display)
        solr_doc.merge!(solr_name('file_type_display', :facetable) => file_type_display)

        solr_doc
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