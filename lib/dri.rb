require "dri/metadata"

module DRI
  autoload :Metadata, "dri/metadata"
  autoload :ModelSupport, "dri/model_support"
  autoload :Vocabulary, "dri/vocabulary"
  autoload :Utils, "dri/utils"
  autoload :Solr, "solr/query"
  autoload :DriRelsVocabulary, "rdf_vocabularies/dri_rels_vocabulary"
  autoload :ModsRelsVocabulary, "rdf_vocabularies/mods_rels_vocabulary"
end
