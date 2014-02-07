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

      # Gathers the file characteristics from the Batch's GenericFiles
      # and adds them to the Batch's Solr document
      def file_metadata_to_solr(solr_doc=Hash.new)
        file_type = []
        file_type_display = []
        file_count = 0
        width = []
        height = []
        area = []
        duration = []
        duration_total = nil
        file_size = []
        file_size_total = nil
        mime_type = []
        channels = []
        bit_depth = []
        sample_rate = []

        if is_collection?
          file_type.push "collection"

          if !is_root_collection? && !ead_level.blank?
            file_type_display.push ead_level.strip.capitalise
          else
            file_type_display.push "Collection"
          end
        end

        solr_query = "is_part_of_ssim:info:fedora/#{pid}"
        results = ActiveFedora::SolrService.query(solr_query, :defType => "edismax")

        if results != nil
          results.each do |gf|
            file_count += 1
            if !is_collection? && gf.key?(solr_name('file_type', :stored_searchable))
              file_type = file_type | [gf[solr_name('file_type', :stored_searchable)][0]]
              file_type_display = file_type_display | [gf[solr_name('file_type', :stored_searchable)][0].capitalize]
            end
            if gf.key?(solr_name('width', :stored_sortable, type: :integer))
              width = width | [gf[solr_name('width', :stored_sortable, type: :integer)]]
            end
            if gf.key?(solr_name('height', :stored_sortable, type: :integer))
              height = height | [gf[solr_name('height', :stored_sortable, type: :integer)]]
            end
            if gf.key?(solr_name('area', :stored_sortable, type: :integer))
              area = area | [gf[solr_name('area', :stored_sortable, type: :integer)]]
            end
            if gf.key?(solr_name('channels', :stored_sortable, type: :integer))
              channels = channels | [gf[solr_name('channels', :stored_sortable, type: :integer)]]
            end
            if gf.key?(solr_name('bit_depth', :stored_sortable, type: :integer))
              bit_depth = bit_depth | [gf[solr_name('bit_depth', :stored_sortable, type: :integer)]]
            end
            if gf.key?(solr_name('sample_rate', :stored_sortable, type: :integer))
              sample_rate = sample_rate | [gf[solr_name('sample_rate', :stored_sortable, type: :integer)]]
            end
            if gf.key?(solr_name('duration', :stored_sortable, type: :integer))
              if (duration_total == nil)
                duration_total = 0
              end
              duration_total += gf[solr_name('duration', :stored_sortable, type: :integer)]
              duration = duration | [gf[solr_name('duration', :stored_sortable, type: :integer)]]
            end
            if gf.key?(solr_name('file_size', :stored_sortable, type: :integer))
              if (file_size_total == nil)
                file_size_total = 0
              end
              file_size_total += gf[solr_name('file_size', :stored_sortable, type: :integer)]
              file_size = file_size | [gf[solr_name('file_size', :stored_sortable, type: :integer)]]
            end
            if gf.key?(solr_name('mime_type', :stored_searchable))
              mime_type = mime_type | gf[solr_name('mime_type', :stored_searchable)]
            end
          end
        end

        if file_type.empty?
          file_type.push "unknown"
          file_type_display.push "Unknown"
        end

        solr_doc.merge!(solr_name('width', :stored_searchable, type: :integer) => width)
        solr_doc.merge!(solr_name('width', :facetable, type: :integer) => width)
        solr_doc.merge!(solr_name('height', :stored_searchable, type: :integer) => height)
        solr_doc.merge!(solr_name('height', :facetable, type: :integer) => height)
        solr_doc.merge!(solr_name('area', :stored_searchable, type: :integer) => area)
        solr_doc.merge!(solr_name('area', :facetable, type: :integer) => area)
        solr_doc.merge!(solr_name('channels', :stored_searchable, type: :integer) => channels)
        solr_doc.merge!(solr_name('channels', :facetable, type: :integer) => channels)
        solr_doc.merge!(solr_name('bit_depth', :stored_searchable, type: :integer) => bit_depth)
        solr_doc.merge!(solr_name('bit_depth', :facetable, type: :integer) => bit_depth)
        solr_doc.merge!(solr_name('width', :stored_searchable, type: :integer) => width)
        solr_doc.merge!(solr_name('width', :facetable, type: :integer) => width)
        solr_doc.merge!(solr_name('sample_rate', :stored_searchable, type: :integer) => sample_rate)
        solr_doc.merge!(solr_name('sample_rate', :facetable, type: :integer) => sample_rate)

        if (duration_total != nil)
          solr_doc.merge!(solr_name('duration_total', :stored_sortable, type: :integer) => [duration_total])
          solr_doc.merge!(solr_name('duration', :stored_searchable) => duration)
          solr_doc.merge!(solr_name('duration', :facetable, type: :integer) => duration)
        end

        if (file_size_total != nil)
          solr_doc.merge!(solr_name('file_size_total', :stored_sortable, type: :integer) => [file_size_total])
          solr_doc.merge!(solr_name('file_size', :stored_searchable, type: :integer) => file_size)
          solr_doc.merge!(solr_name('file_size', :facetable, type: :integer) => file_size)
        end

        solr_doc.merge!(solr_name('file_type_display', :stored_searchable) => file_type_display)
        solr_doc.merge!(solr_name('file_type_display', :facetable) => file_type_display)

        solr_doc.merge!(solr_name('mime_type', :stored_searchable) => mime_type)
        solr_doc.merge!(solr_name('mime_type', :facetable) => mime_type)

        solr_doc.merge!(solr_name('file_count', :stored_sortable, type: :integer) => [file_count])

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