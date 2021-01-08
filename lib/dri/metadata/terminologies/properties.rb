module DRI::Metadata::Terminologies
  module Properties
    # Set OM (Opinionated Metadata) terminology
    def load_inherited_terminology
      set_terminology do |t|
        # Selects the root node of the XML document
        t.root(path: 'properties', xmlns: '', namespace_prefix: nil)
        t.metadata_md5(namespace_prefix: nil, index_as: [:stored_searchable])
        t.model_version(namespace_prefix: nil, path: 'model_version')
        t.doi(namespace_prefix: nil, index_as: [:stored_searchable, :displayable])
        t.cover_image(namespace_prefix: nil, index_as: [:stored_searchable, :displayable])
        t.institute(namespace_prefix: nil, index_as: [:stored_searchable, :displayable, :facetable])
        t.depositing_institute(namespace_prefix: nil, index_as: [:stored_searchable, :displayable])
        t.licence(namespace_prefix: nil, index_as: [:stored_searchable, :displayable, :facetable])
        t.published_at(namespace_prefix: nil, index_as: [:stored_searchable])
      end # set_terminology
    end
  end
end
