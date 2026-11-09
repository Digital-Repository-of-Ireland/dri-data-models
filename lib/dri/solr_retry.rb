# frozen_string_literal: true
module DRI
  module SolrRetry
    TRANSIENT = [Errno::ECONNRESET, Net::ReadTimeout, Net::OpenTimeout].freeze

    def self.with_retries(attempts: 3, wait: 30)
      tries = 0
      begin
        yield
      rescue RSolr::Error::Http => e
        status = e.response && e.response[:status].to_i
        raise unless status && status >= 500   # never retry 4xx
        tries += 1
        raise if tries >= attempts
        Rails.logger.warn("Solr #{status}, retry #{tries}/#{attempts} in #{wait}s")
        sleep wait
        retry
      rescue *TRANSIENT => e
        tries += 1
        raise if tries >= attempts
        Rails.logger.warn("#{e.class}, retry #{tries}/#{attempts} in #{wait}s")
        sleep wait
        retry
      end
    end
  end
end
