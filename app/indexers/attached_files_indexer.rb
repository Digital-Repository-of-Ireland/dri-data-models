# frozen_string_literal: true
class AttachedFilesIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    solr_doc = {}
    return solr_doc if resource.wrapped_object.attached_files.blank?

    resource.wrapped_object.declared_attached_files.each do |name, file|
      solr_doc.merge! file.to_solr(solr_doc, name: name.to_s)
    end

    solr_doc
  end
end
