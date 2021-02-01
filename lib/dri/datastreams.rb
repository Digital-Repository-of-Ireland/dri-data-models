# frozen_string_literal: true
module DRI
  module Datastreams
    autoload :OmDatastream, 'dri/datastreams/om_datastream'
    autoload :NokogiriDatastream, 'dri/datastreams/nokogiri_datastream'
    autoload :Persistence, 'dri/datastreams/persistence'
  end
end
