# spec/metadata.dublin_core_audio_spec.rb
require 'spec_helper'

describe "DRI::Metadata::DublinCoreAudio" do

  before(:each) do
    @dc = fixture("audios/dublin_core_audio_sample1.xml")
    @ds = DRI::Metadata::DublinCoreAudio.from_xml(@dc)
  end

  it "should expose common metadata info for audio" do
    @ds.title.should == ["THE SAMPLE AUDIO TITLE"]
    @ds.description.should == ["SAMPLE DESCRIPTION"]
    @ds.language.should == ["en"]
    @ds.subject.should == ["subject1","subject2","subject3"]
    @ds.subject(0).subject_lang.should == ["ga"]
    @ds.subject(1).subject_lang.should == []
    @ds.subject(2).subject_lang.should == ["ga"]
    @ds.subject(0).should == ["subject1"]
  end

  it "should expose specific audio metadata" do
    @ds.broadcast_date == ["2000-01-01"]
    @ds.role_hst.should == ["Valera, Eamonn, de"]
    @ds.guest.should == ["Collins, Michael", "Connolly, James"]
  end

 it "should expose speficic geocode metadata" do
    @ds.geocode_point == ["SAMPLE POINT"]
    @ds.geocode_box == ["SAMPLE BOX"]
 end

  it "should have access to MARC Relators" do
    @ds.role_hst = ["Collins, Michael"]
    @ds.role_hst.should == ["Collins, Michael"]
  end

  # Dublin Core does not define a parent element for it's metadata fields
  # This test ensures that DublinCoreAudio can generate Dublin Core elements
  # within any parent element.
  it "should insert Dublin Core into any given parent element" do
    @ds.language = "ga"
    @xml1 = Nokogiri::XML(@ds.to_xml)

    @ds2 = DRI::Metadata::DublinCoreAudio.from_xml(fixture("audios/dublin_core_audio_diff_root.xml"))
    @ds2.title = "MODIFIED AUDIO TITLE"
    @xml2 = Nokogiri::XML(@ds2.to_xml)

    @ds3 = DRI::Metadata::DublinCoreAudio.new
    @ds3.title = "MODIFIED AUDIO TITLE"
    @xml3 = Nokogiri::XML(@ds3.to_xml)

    @root1 = @xml1.xpath("//dc:language[. = 'ga']", :dc => "http://purl.org/dc/elements/1.1/").first.parent
    @root1.name.should == "qualifieddc"
    @root1.namespace.should == nil
    @root1.attr("xsi:noNamespaceSchemaLocation").should == "http://dublincore.org/schemas/xmls/qdc/2008/02/11/qualifieddc.xsd"

    @root2 = @xml2.xpath("//dc:title[. = 'MODIFIED AUDIO TITLE']", :dc => "http://purl.org/dc/elements/1.1/").first.parent
    @root2.name.should == "dc"
    @root2.namespace.prefix.should == "oai_dc"
    @root2.namespace.href.should == "http://www.openarchives.org/OAI/2.0/oai_dc/"

    @root3 = @xml3.xpath("//dc:title[. = 'MODIFIED AUDIO TITLE']", :dc => "http://purl.org/dc/elements/1.1/").first.parent
    @root3.name.should == "qualifieddc"
    @root3.namespace.should == nil
    @root3.attr("xsi:noNamespaceSchemaLocation").should == "http://dublincore.org/schemas/xmls/qdc/2008/02/11/qualifieddc.xsd" 
  end
end
