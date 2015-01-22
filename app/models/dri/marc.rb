module DRI
class Marc < DRI::Batch 

  include DRI::ModelSupport::MarcSupport

  has_attributes :leader, datastream: :descMetadata, multiple: false
  has_attributes :controlfield, :controlfield_tag, datastream: :descMetadata, multiple: true
  has_attributes :datafield, :datafield_tag, :datafield_ind1, :datafield_ind2, datastream: :descMetadata, multiple: true        

  around_save :create_multiple_records

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

    if (xml_text.is_a? Nokogiri::XML::Document)
      xml = xml_text
    else
      xml = Nokogiri::XML xml_text
    end

    xml_without_blanks = Nokogiri::XML.parse(xml.to_xml) do |config|
      config.noblanks
    end

    fullMetadata.ng_xml = xml_without_blanks
    object = split_xml xml_without_blanks
    descMetadata.ng_xml = object

    return true
  end

  def split_xml xml_text
    collection = xml_text.search("//collection")
    records = collection.children
    record = records[0]

    collection[0].children.remove
    collection[0].add_child(record)
    
    return collection[0].to_xml
  end

  def attributes=(properties)
    controlfields = properties.delete('controlfield')
    datafields = properties.delete('datafield')
    super(properties)

    self.descMetadata.add_controlfields(controlfields) unless controlfields.nil?
    self.descMetadata.add_datafields(datafields) unless datafields.nil?
  end

  def create_multiple_records
    yield
    if !new_record? && self.fullMetadata.ng_xml.search("//record").count > 1
      begin
        Sufia.queue.push(CreateMarcRecordsJob.new(self.pid))
      rescue Exception => e
      end
    end
  end
      
end
end
