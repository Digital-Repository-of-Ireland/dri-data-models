# DRI namespace
module DRI
  # RDFVocabularies namespace
  module RDFVocabularies
    # Defines DRI relationships RDF properties
    class DriRelsVocabulary < RDF::Vocabulary('http://dri.ie/ns/relations#')
      property :isPrecededBy
      property :isDocumentationFor
    end
  end
end