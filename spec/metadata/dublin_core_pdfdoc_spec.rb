# spec/metadata.dublin_core_pdfdoc_spec.rb
require 'spec_helper'

describe "DRI::Metadata::DublinCorePdfdoc" do

  before(:each) do
    @dc = fixture("pdfs/dublin_core_pdfdoc_sample.xml")
    @ds = DRI::Metadata::DublinCorePdfdoc.from_xml(@dc)
  end

  it "should expose common metadata info for pdfdoc" do
    @ds.title.should == ["THE SAMPLE PDF TITLE"]
    @ds.description.should == ["SAMPLE DESCRIPTION"]
    @ds.language.should == ["en"]
    @ds.subject.should == ["subject1","subject2","subject3"]
    @ds.subject(0).should == ["subject1"]
  end

  it "should expose specific document/article metadata" do
    @ds.author.should == ["Kenny, Stuart"] 
    @ds.editor.should == ["Cassidy, Kathryn"]
  end

  # Dublin Core does not define a parent element for it's metadata fields
  # This test ensures that DublinCorePdfdoc can generate Dublin Core elements
  # within any parent element.
  it "should insert Dublin Core into any given parent element" do
    @ds.language = "ga"
    @xml1 = Nokogiri::XML(@ds.to_xml)

    @ds2 = DRI::Metadata::DublinCorePdfdoc.from_xml(fixture("pdfs/dublin_core_pdfdoc_diff_root.xml"))
    @ds2.title = "MODIFIED PDF TITLE"
    @xml2 = Nokogiri::XML(@ds2.to_xml)

    @ds3 = DRI::Metadata::DublinCorePdfdoc.new
    @ds3.title = "MODIFIED PDF TITLE"
    @xml3 = Nokogiri::XML(@ds3.to_xml)

    @root1 = @xml1.xpath("//dc:language[. = 'ga']", :dc => "http://purl.org/dc/elements/1.1/").first.parent
    @root1.name.should == "qualifieddc"
    @root1.namespace.should == nil
    @root1.attr("xsi:noNamespaceSchemaLocation").should == "http://dublincore.org/schemas/xmls/qdc/2008/02/11/qualifieddc.xsd"

    @root2 = @xml2.xpath("//dc:title[. = 'MODIFIED PDF TITLE']", :dc => "http://purl.org/dc/elements/1.1/").first.parent
    @root2.name.should == "dc"
    @root2.namespace.prefix.should == "oai_dc"
    @root2.namespace.href.should == "http://www.openarchives.org/OAI/2.0/oai_dc/"

    @root3 = @xml3.xpath("//dc:title[. = 'MODIFIED PDF TITLE']", :dc => "http://purl.org/dc/elements/1.1/").first.parent
    @root3.name.should == "qualifieddc"
    @root3.namespace.should == nil
    @root3.attr("xsi:noNamespaceSchemaLocation").should == "http://dublincore.org/schemas/xmls/qdc/2008/02/11/qualifieddc.xsd" 
  end
end
