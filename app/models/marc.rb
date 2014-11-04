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

  def update_metadata xml_text
    if (xml_text.is_a? File)
      xml_text = xml_text.read
    end

    objects = split_xml xml_text
    descMetadata.ng_xml = objects[0]

    objects[1..-1].each do |o|
      new_object = Batch.with_standard :marc
      new_object.governing_collection = governing_collection
      new_object.depositor = depositor
      new_object.status = status
      new_object.update_metadata o
      new_object.datastreams['rightsMetadata'].content = rightsMetadata.content

      MetadataHelpers.checksum_metadata(new_object)

      if new_object.valid?
        new_object.save
      end
    end

    return true
  end

  def split_xml xml_text
    if (xml_text.is_a? Nokogiri::XML::Document)
      xml = xml_text
    else
      xml = Nokogiri::XML xml_text
    end
  
    collection = xml.search("//collection")
    records = collection.children

    objects = []
    records.each do |r|
      unless r.blank?
        collection[0].children.remove
        collection[0].add_child(r)
        objects << collection[0].to_xml
      end
    end

    return objects
  end

  def attributes=(properties)
    controlfields = properties.delete('controlfield')
    datafields = properties.delete('datafield')
    super(properties)

    self.descMetadata.add_controlfields(controlfields) unless controlfields.nil?
    self.descMetadata.add_datafields(datafields) unless datafields.nil?
  end
      
end
