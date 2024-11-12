# DRI namespace
module DRI
  # RDFVocabularies namespace
  module RdfVocabularies
    # Defines DRI relationships RDF properties
    class DRIRelsVocabulary < RDF::Vocabulary('http://dri.ie/ns/relations#')
      property :isPrecededBy
      property :isDocumentationFor
    end
  end
end
