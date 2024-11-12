# frozen_string_literal: true
require 'dri/metadata'

module DRI
  autoload :Metadata, 'dri/metadata'
  autoload :ModelSupport, 'dri/model_support'
  autoload :Vocabulary, 'dri/vocabulary'
  autoload :Utils, 'dri/utils'
  autoload :Checksum, 'dri/checksum'
  autoload :RdfVocabularies, 'dri/rdf_vocabularies'
  autoload :Datastreams, 'dri/datastreams'
  autoload :Derivatives, 'dri/derivatives'
  autoload :Indexing, 'dri/indexing'

  attr_writer :queue

  def self.queue
    @queue ||= DRI::Resque::Queue.new('dri')
  end

  def self.table_name_prefix
    'dri_'
  end
end

