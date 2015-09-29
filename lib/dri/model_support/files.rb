module DRI
  module ModelSupport
  	module Files
      extend ActiveSupport::Concern
      require 'open-uri'
      require 'uri'
      require 'tempfile'

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
        file_format = []

        if is_collection?
          file_type.push "collection"
          file_type_display.push "Collection"
        end

        solr_query = "#{ActiveFedora::SolrQueryBuilder.solr_name('isPartOf', :stored_searchable, type: :symbol)}:\"#{id}\""        
        results = ActiveFedora::SolrService.query(solr_query, :defType => "edismax")

        if results != nil
          results.each do |gf|
            file_count += 1
            if !is_collection? && gf.key?(ActiveFedora::SolrQueryBuilder.solr_name('file_type', :stored_searchable))
              file_type = file_type | [gf[ActiveFedora::SolrQueryBuilder.solr_name('file_type', :stored_searchable)][0]]
              file_type_display = file_type_display | [gf[ActiveFedora::SolrQueryBuilder.solr_name('file_type', :stored_searchable)][0].capitalize]
            end
            if gf.key?(ActiveFedora::SolrQueryBuilder.solr_name('width', :stored_sortable, type: :integer))
              width = width | [gf[ActiveFedora::SolrQueryBuilder.solr_name('width', :stored_sortable, type: :integer)]]
            end
            if gf.key?(ActiveFedora::SolrQueryBuilder.solr_name('height', :stored_sortable, type: :integer))
              height = height | [gf[ActiveFedora::SolrQueryBuilder.solr_name('height', :stored_sortable, type: :integer)]]
            end
            if gf.key?(ActiveFedora::SolrQueryBuilder.solr_name('area', :stored_sortable, type: :integer))
              area = area | [gf[ActiveFedora::SolrQueryBuilder.solr_name('area', :stored_sortable, type: :integer)]]
            end
            if gf.key?(ActiveFedora::SolrQueryBuilder.solr_name('channels', :stored_sortable, type: :integer))
              channels = channels | [gf[ActiveFedora::SolrQueryBuilder.solr_name('channels', :stored_sortable, type: :integer)]]
            end
            if gf.key?(ActiveFedora::SolrQueryBuilder.solr_name('bit_depth', :stored_sortable, type: :integer))
              bit_depth = bit_depth | [gf[ActiveFedora::SolrQueryBuilder.solr_name('bit_depth', :stored_sortable, type: :integer)]]
            end
            if gf.key?(ActiveFedora::SolrQueryBuilder.solr_name('sample_rate', :stored_sortable, type: :integer))
              sample_rate = sample_rate | [gf[ActiveFedora::SolrQueryBuilder.solr_name('sample_rate', :stored_sortable, type: :integer)]]
            end
            if gf.key?(ActiveFedora::SolrQueryBuilder.solr_name('duration', :stored_sortable, type: :integer))
              if (duration_total == nil)
                duration_total = 0
              end
              duration_total += gf[ActiveFedora::SolrQueryBuilder.solr_name('duration', :stored_sortable, type: :integer)]
              duration = duration | [gf[ActiveFedora::SolrQueryBuilder.solr_name('duration', :stored_sortable, type: :integer)]]
            end
            if gf.key?(ActiveFedora::SolrQueryBuilder.solr_name('file_size', :stored_sortable, type: :integer))
              if (file_size_total == nil)
                file_size_total = 0
              end
              file_size_total += gf[ActiveFedora::SolrQueryBuilder.solr_name('file_size', :stored_sortable, type: :integer)]
              file_size = file_size | [gf[ActiveFedora::SolrQueryBuilder.solr_name('file_size', :stored_sortable, type: :integer)]]
            end
            if gf.key?(ActiveFedora::SolrQueryBuilder.solr_name('mime_type', :stored_searchable))
              mime_type = mime_type | gf[ActiveFedora::SolrQueryBuilder.solr_name('mime_type', :stored_searchable)]
            end
            if gf.key?(ActiveFedora::SolrQueryBuilder.solr_name('file_format', :stored_searchable))
              file_format = file_format | gf[ActiveFedora::SolrQueryBuilder.solr_name('file_format', :stored_searchable)]
            end
          end
        end

        if file_type.empty?
          # FIXME Use Vocabulary.dcmiType rather that if-elsif
          # As a last resort try to determine the file type from the
          # DCMI vocabulary in the metadata.
          #
          type = self.descMetadata.type
          if type.include?("Sound")
            file_type.push "audio"
            file_type_display.push "Audio"
          elsif type.include?("MovingImage")
            file_type.push "video"
            file_type_display.push "Video"
          elsif type.include?("Text")
            file_type.push "text"
            file_type_display.push "Text"
          elsif type.include?("Image")
            file_type.push "image"
            file_type_display.push "Image"
          elsif (type.include?("Collection") || is_collection?)
            file_type.push "collection"
            file_type_display.push "Collection"
          else
            file_type.push "unknown"
            file_type_display.push "Unknown"
          end
        end

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('width', :stored_searchable, type: :integer) => width)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('width', :facetable, type: :integer) => width)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('height', :stored_searchable, type: :integer) => height)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('height', :facetable, type: :integer) => height)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('area', :stored_searchable, type: :integer) => area)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('area', :facetable, type: :integer) => area)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('channels', :stored_searchable, type: :integer) => channels)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('channels', :facetable, type: :integer) => channels)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('bit_depth', :stored_searchable, type: :integer) => bit_depth)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('bit_depth', :facetable, type: :integer) => bit_depth)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('width', :stored_searchable, type: :integer) => width)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('width', :facetable, type: :integer) => width)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('sample_rate', :stored_searchable, type: :integer) => sample_rate)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('sample_rate', :facetable, type: :integer) => sample_rate)

        if duration_total != nil
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('duration_total', :stored_sortable, type: :integer) => [duration_total])
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('duration', :stored_searchable) => duration)
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('duration', :facetable, type: :integer) => duration)
        end

        if file_size_total != nil
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('file_size_total', :stored_sortable, type: :integer) => [file_size_total])
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('file_size', :stored_searchable, type: :integer) => file_size)
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('file_size', :facetable, type: :integer) => file_size)
        end

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('file_type', :stored_searchable) => file_type)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('file_type', :facetable) => file_type)

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('file_type_display', :stored_searchable) => file_type_display)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('file_type_display', :facetable) => file_type_display)

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('mime_type', :stored_searchable) => mime_type)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('mime_type', :facetable) => mime_type)

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('file_format', :stored_searchable) => file_format)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('file_format', :facetable) => file_format)

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('file_count', :stored_sortable, type: :integer) => [file_count])

        solr_doc
      end # file_metadata_to_solr

    end # module

  end # module

end # module
