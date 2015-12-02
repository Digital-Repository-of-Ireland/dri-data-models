# DRI namespace
module DRI
  # RDFVocabularies namespace
  module RDFVocabularies
    # Defines DRI MDOS relationships RDF properties
    class ModsRelsVocabulary < RDF::Vocabulary('http://www.loc.gov/mods/rdf/v1#')
      # MODS RDF relationships (http://www.loc.gov/standards/mods/modsrdf-primer.html#relatedItem)
      # preceding, succeeding, original, host, constituent, series,
      # otherVersion, otherFormat, isReferencedBy, references, reviewOf
      property :relatedPreceding
      property :relatedSucceeding
      property :relatedOriginal
      property :relatedHost
      property :relatedConstituent
      property :relatedSeries
      property :relatedVersion
      property :relatedFormat
      property :relatedReferencedBy
      property :relatedReference
      property :relatedReview
    end
  end
end