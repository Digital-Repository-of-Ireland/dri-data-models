module DRI
  class Related < ActiveFedora::Base
    has_and_belongs_to_many :related,
                            predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasMember,
                            class_name: 'DRI::Batch'
  end
end
