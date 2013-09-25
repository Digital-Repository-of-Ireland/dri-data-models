class FileContentDatastream < ActiveFedora::Datastream
  include Sufia::FileContent::ExtractMetadata
  include Sufia::FileContent::Versions

  # overwrite Sufia implemention with original Rubydora version,
  # otherwise we will not be able to save datastreams with
  # references to files
  def has_content?
      # persisted objects are required to have content
      return true unless new?

      # type E and R objects should have content.
      return !dsLocation.blank? if ['E','R'].include? controlGroup

      # if we've set content, then we have content.

      # return true if instance_variable_defined? :@content

      behaves_like_io?(@content) || !content.blank?
  end
end