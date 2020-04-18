# DRI namespace
module DRI
  # ModelSupport namespace
  module ModelSupport
    # Includes AF properties, digital object management methods that are common to all the DRI digital object classes
    module Files
      extend ActiveSupport::Concern
      require 'open-uri'
      require 'uri'
      require 'tempfile'

      # Gathers the file characteristics from the Object's GenericFiles
      # and adds them to the Object's Solr document
      # @param solr_doc [Hash] the solr document hash for the object
      # @return [Hash] solr_doc hash for index
      def file_metadata_to_solr(solr_doc = {})
        if collection?
          file_type =  ['collection']
          file_type_display = ['Collection']

          solr_doc.merge!(Solrizer.solr_name('file_type', :stored_searchable) => file_type)
          solr_doc.merge!(Solrizer.solr_name('file_type', :facetable) => file_type)

          solr_doc.merge!(Solrizer.solr_name('file_type_display', :stored_searchable) => file_type_display)
          solr_doc.merge!(Solrizer.solr_name('file_type_display', :facetable) => file_type_display)
        end

        no_of_files = generic_files.count
        solr_doc = index_file_metadata(no_of_files, solr_doc) if no_of_files > 0

        unless solr_doc.key?(Solrizer.solr_name('file_type', :stored_searchable))
          solr_doc = file_type_from_metadata(solr_doc)
        end

        solr_doc
      end # file_metadata_to_solr

      def index_file_metadata(no_of_files, solr_doc = {})
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
        file_format = []

        solr_query = "#{Solrizer.solr_name('isPartOf', :stored_searchable, type: :symbol)}:\"#{noid}\""
        results = ActiveFedora::SolrService.query(solr_query, rows: no_of_files, defType: 'edismax')

        unless results.nil?
          results.each do |gf|
            file_count += 1
            if !collection? && gf.key?(Solrizer.solr_name('file_type', :stored_searchable))
              file_type |= [gf[Solrizer.solr_name('file_type', :stored_searchable)][0]]
              file_type_display |= [gf[Solrizer.solr_name('file_type', :stored_searchable)][0].capitalize]
            end
            if gf.key?(Solrizer.solr_name('width', :stored_sortable, type: :integer))
              width |= [gf[Solrizer.solr_name('width', :stored_sortable, type: :integer)]]
            end
            if gf.key?(Solrizer.solr_name('height', :stored_sortable, type: :integer))
              height |= [gf[Solrizer.solr_name('height', :stored_sortable, type: :integer)]]
            end
            if gf.key?(Solrizer.solr_name('area', :stored_sortable, type: :integer))
              area |= [gf[Solrizer.solr_name('area', :stored_sortable, type: :integer)]]
            end
            if gf.key?(Solrizer.solr_name('channels', :stored_sortable, type: :integer))
              channels |= [gf[Solrizer.solr_name('channels', :stored_sortable, type: :integer)]]
            end
            if gf.key?(Solrizer.solr_name('bit_depth', :stored_sortable, type: :integer))
              bit_depth |= [gf[Solrizer.solr_name('bit_depth', :stored_sortable, type: :integer)]]
            end
            if gf.key?(Solrizer.solr_name('sample_rate', :stored_sortable, type: :integer))
              sample_rate |= [gf[Solrizer.solr_name('sample_rate', :stored_sortable, type: :integer)]]
            end
            if gf.key?(Solrizer.solr_name('duration', :stored_sortable, type: :integer))
              duration_total = 0 if duration_total.nil?
              duration_total += gf[Solrizer.solr_name('duration', :stored_sortable, type: :integer)]
              duration |= [gf[Solrizer.solr_name('duration', :stored_sortable, type: :integer)]]
            end
            if gf.key?(Solrizer.solr_name('file_size', :stored_sortable, type: :integer))
              file_size_total = 0 if file_size_total.nil?
              file_size_total += gf[Solrizer.solr_name('file_size', :stored_sortable, type: :integer)]
              file_size |= [gf[Solrizer.solr_name('file_size', :stored_sortable, type: :integer)]]
            end
            if gf.key?(Solrizer.solr_name('mime_type', :stored_searchable))
              mime_type |= gf[Solrizer.solr_name('mime_type', :stored_searchable)]
            end
            if gf.key?(Solrizer.solr_name('file_format', :stored_searchable))
              file_format |= gf[Solrizer.solr_name('file_format', :stored_searchable)]
            end
          end
        end

        solr_doc.merge!(Solrizer.solr_name('width', :stored_searchable, type: :integer) => width)
        solr_doc.merge!(Solrizer.solr_name('width', :facetable, type: :integer) => width)
        solr_doc.merge!(Solrizer.solr_name('height', :stored_searchable, type: :integer) => height)
        solr_doc.merge!(Solrizer.solr_name('height', :facetable, type: :integer) => height)
        solr_doc.merge!(Solrizer.solr_name('area', :stored_searchable, type: :integer) => area)
        solr_doc.merge!(Solrizer.solr_name('area', :facetable, type: :integer) => area)
        solr_doc.merge!(Solrizer.solr_name('channels', :stored_searchable, type: :integer) => channels)
        solr_doc.merge!(Solrizer.solr_name('channels', :facetable, type: :integer) => channels)
        solr_doc.merge!(Solrizer.solr_name('bit_depth', :stored_searchable, type: :integer) => bit_depth)
        solr_doc.merge!(Solrizer.solr_name('bit_depth', :facetable, type: :integer) => bit_depth)
        solr_doc.merge!(Solrizer.solr_name('width', :stored_searchable, type: :integer) => width)
        solr_doc.merge!(Solrizer.solr_name('width', :facetable, type: :integer) => width)
        solr_doc.merge!(Solrizer.solr_name('sample_rate', :stored_searchable, type: :integer) => sample_rate)
        solr_doc.merge!(Solrizer.solr_name('sample_rate', :facetable, type: :integer) => sample_rate)

        unless duration_total.nil?
          solr_doc.merge!(Solrizer.solr_name('duration_total', :stored_sortable, type: :integer) => [duration_total])
          solr_doc.merge!(Solrizer.solr_name('duration', :stored_searchable) => duration)
          solr_doc.merge!(Solrizer.solr_name('duration', :facetable, type: :integer) => duration)
        end

        unless file_size_total.nil?
          solr_doc.merge!(Solrizer.solr_name('file_size_total', :stored_sortable, type: :integer) => [file_size_total])
          solr_doc.merge!(Solrizer.solr_name('file_size', :stored_searchable, type: :integer) => file_size)
          solr_doc.merge!(Solrizer.solr_name('file_size', :facetable, type: :integer) => file_size)
        end

        unless file_type.empty?
          solr_doc.merge!(Solrizer.solr_name('file_type', :stored_searchable) => file_type)
          solr_doc.merge!(Solrizer.solr_name('file_type', :facetable) => file_type)

          solr_doc.merge!(Solrizer.solr_name('file_type_display', :stored_searchable) => file_type_display)
          solr_doc.merge!(Solrizer.solr_name('file_type_display', :facetable) => file_type_display)
        end

        solr_doc.merge!(Solrizer.solr_name('mime_type', :stored_searchable) => mime_type)
        solr_doc.merge!(Solrizer.solr_name('mime_type', :facetable) => mime_type)

        solr_doc.merge!(Solrizer.solr_name('file_format', :stored_searchable) => file_format)
        solr_doc.merge!(Solrizer.solr_name('file_format', :facetable) => file_format)

        solr_doc.merge!(Solrizer.solr_name('file_count', :stored_sortable, type: :integer) => [file_count])

        solr_doc
      end

      def file_type_from_metadata(solr_doc)
        # As a last resort try to determine the file type from the
        # DCMI vocabulary in the metadata.
        file_type = []
        file_type_display = []

        type.each do |value|
          next unless DRI::Vocabulary.dcmi_type.include?(value.capitalize)
          file_type.push(value)
          file_type_display.push(value.capitalize)
          break
        end

        if file_type.empty?
          file_type.push 'unknown'
          file_type_display.push 'Unknown'
        end

        solr_doc.merge!(Solrizer.solr_name('file_type', :stored_searchable) => file_type)
        solr_doc.merge!(Solrizer.solr_name('file_type', :facetable) => file_type)

        solr_doc.merge!(Solrizer.solr_name('file_type_display', :stored_searchable) => file_type_display)
        solr_doc.merge!(Solrizer.solr_name('file_type_display', :facetable) => file_type_display)

        solr_doc
      end
    end # module
  end # module
end # module
