require 'dri/metadata'

module DRI
  autoload :Metadata, 'dri/metadata'
  autoload :ModelSupport, 'dri/model_support'
  autoload :Vocabulary, 'dri/vocabulary'
  autoload :Utils, 'dri/utils'
  autoload :Checksum, 'dri/checksum'
  autoload :Solr, 'solr/query'
  autoload :RDFVocabularies, 'dri/rdf_vocabularies'
  autoload :Datastreams, 'dri/datastreams'
  autoload :OmDatastream, 'dri/om_datastream'

  attr_writer :queue

  def self.queue
    @queue ||= DRI::Resque::Queue.new('dri')
  end

end
