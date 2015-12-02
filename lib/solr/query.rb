# Solr namespace
module Solr
  # Implements Solr query methods
  class Query
    # Constructor
    # @param query [String] the solr query string
    # @param chunk [Integer] the chunk of results for pagination
    # @param args [Hash] the hash with solr query options
    def initialize(query, chunk=100, args = {})
      @query = query
      @chunk = chunk
      @args = args
      @cursor_mark = '*'
      @has_more = true
    end

    # Handles Solr queries to AF SolrService
    def query
      query_args = @args.merge({ raw: true, rows: @chunk, sort: 'id asc', cursorMark: @cursor_mark })

      result = ActiveFedora::SolrService.query(@query, query_args)

      result_docs = result['response']['docs']

      nextCursorMark = result['nextCursorMark']

      @has_more = false if @cursor_mark == nextCursorMark

      @cursor_mark = nextCursorMark

      result_docs
    end

    # Determine whether there are more results to process
    # @return [Boolean] true if more results; false otherwise
    def has_more?
      @has_more
    end

    # Extract chunk of results from query
    # @return [Array[Solr::Document]] array of solr document results
    def pop
      self.query
    end
  end
end
