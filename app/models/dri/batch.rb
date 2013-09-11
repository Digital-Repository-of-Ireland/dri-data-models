# A redoing of Sufia::Models::Batch
module DRI
  module Model
    class Batch < ActiveFedora::Base
      include ActiveFedora::Auditable
      include Hydra::ModelMixins::RightsMetadata
      include Sufia::ModelMethods
      include Sufia::Noid
      include DRI::Model::InterchangeableMetadata
      
      
      has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

      belongs_to :governing_collection, :property=>:is_governed_by, :class_name => 'DRI::Model::Collection'
      has_many :collections, :property=>:is_member_of_collection, :class_name => 'DRI::Model::Collection'
      has_many :generic_files, :property => :is_part_of

      def self.find_or_create(pid)
        begin
          Batch.find(pid)
        rescue ActiveFedora::ObjectNotFoundError
          Batch.create({pid: pid})
        end
      end

      def to_solr(solr_doc={}, opts={})
        super(solr_doc, opts)
        solr_doc[Solrizer.solr_name('noid', Sufia::GenericFile.noid_indexer)] = noid
        return solr_doc
      end

    end
  end
end