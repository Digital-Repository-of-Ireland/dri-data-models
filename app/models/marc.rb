class Marc < Batch 

  has_attributes :leader, datastream: :descMetadata, multiple: false
  has_attributes :controlfield, :controlfield_tag, datastream: :descMetadata, multiple: true
  has_attributes :datafield, :datafield_tag, :datafield_ind1, :datafield_ind2, datastream: :descMetadata, multiple: true        

  def initialize(params = {})
    params[:desc_metadata_class] = "DRI::Metadata::Marc"
    super(params)
  end

  def type
    descMetadata.type
  end

  def attributes=(properties)
    controlfields = properties.delete('controlfield')
    datafields = properties.delete('datafield')
    super(properties)

    self.descMetadata.add_controlfields(controlfields) unless controlfields.nil?
    self.descMetadata.add_datafields(datafields) unless datafields.nil?
  end
      
end
