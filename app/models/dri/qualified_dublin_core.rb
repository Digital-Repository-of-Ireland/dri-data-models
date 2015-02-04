module DRI
class QualifiedDublinCore < DRI::Batch

  # Full Simple DC Title, Creator, Subject, Description, Publisher, Contributor, Date, Type, Format, Identifier, Source,
  # Language, Relation, Coverage, Rights
  # All DC elements added to the DM - Simple DC Ingest form
  has_attributes :date, datastream: :descMetadata, multiple: true
  has_attributes :relation, datastream: :descMetadata, multiple: true
  has_attributes :source, datastream: :descMetadata, multiple: true
  has_attributes :geographical_coverage, datastream: :descMetadata, multiple: true
  has_attributes :temporal_coverage, datastream: :descMetadata, multiple: true
  has_attributes :type, datastream: :descMetadata, multiple: true
  has_attributes :format, datastream: :descMetadata, multiple: true
  has_attributes :coverage, datastream: :descMetadata, multiple: true
  has_attributes :identifier, datastream: :descMetadata, multiple: true
  has_attributes :geocode_point, datastream: :descMetadata, multiple: true
  has_attributes :geocode_box, datastream: :descMetadata, multiple: true
  has_attributes  *(DRI::Vocabulary::marcRelators.map { |s| s.prepend("role_").to_sym}), datastream: :descMetadata,
                                 multiple: true         

  def initialize(args = {})
    args[:desc_metadata_class] = "DRI::Metadata::QualifiedDublinCore"
    super(args)
  end

  def model_name
    DRI::Batch.model_name
  end

  def roles= roles
    if descMetadata.class == DRI::Metadata::QualifiedDublinCore
      descMetadata.roles = roles
    end
  end

  def attributes=(properties)
    super(properties)
  end

  def self.find_or_create(pid)
    begin
      DRI::QualifiedDublinCore.find(pid)
    rescue ActiveFedora::ObjectNotFoundError
      DRI::QualifiedDublinCore.create({pid: pid})
    end
  end
      
end
end
