class FileContentDatastream < ActiveFedora::File
  include DRI::Derivatives::ExtractMetadata

  def latest_version
    versions.last unless versions.empty?
  end
end
