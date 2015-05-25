module DRI
  module RDFVocabularies
    class DriRelsVocabulary < RDF::Vocabulary("http://dri.ie/ns/relations#")
      property :isPrecededBy
      property :isDocumentationFor
    end
  end
end