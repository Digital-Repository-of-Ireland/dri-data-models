# spec/metadata.dublin_core_collection_spec.rb
require 'spec_helper'

describe "DRI::Metadata::DublinCoreCollection" do

  before(:each) do
    @dc = fixture("collections/dublin_core_collection_sample.xml")
    @ds = DRI::Metadata::DublinCoreCollection.from_xml(@dc)
  end

  it "should expose common metadata info for collection" do
    @ds.title.should == ["SAMPLE COLLECTION TITLE"]
    @ds.description.should == ["SAMPLE COLLECTION DESCRIPTION"]
    @ds.publisher.should == ["SAMPLE INSTITUTION"]
  end

  # Dublin Core does not define a parent element for it's metadata fields
  # This test ensures that DublinCoreCollection can generate Dublin Core elements
  # within any parent element.
  it "should insert Dublin Core into any given parent element" do
    @ds.description = "MODIFIED COLLECTION DESCRIPTION"
    @xml1 = Nokogiri::XML(@ds.to_xml)

    @ds2 = DRI::Metadata::DublinCoreCollection.from_xml(fixture("collections/dublin_core_collection_diff_root.xml"))
    @ds2.title = "MODIFIED COLLECTION TITLE"
    @xml2 = Nokogiri::XML(@ds2.to_xml)

    @ds3 = DRI::Metadata::DublinCoreCollection.new
    @ds3.title = "MODIFIED COLLECTION TITLE"
    @xml3 = Nokogiri::XML(@ds3.to_xml)

    @root1 = @xml1.xpath("//dc:description[. = 'MODIFIED COLLECTION DESCRIPTION']", :dc => "http://purl.org/dc/elements/1.1/").first.parent
    @root1.name.should == "qualifieddc"
    @root1.namespace.should == nil
    @root1.attr("xsi:noNamespaceSchemaLocation").should == "http://dublincore.org/schemas/xmls/qdc/2008/02/11/qualifieddc.xsd"

    @root2 = @xml2.xpath("//dc:title[. = 'MODIFIED COLLECTION TITLE']", :dc => "http://purl.org/dc/elements/1.1/").first.parent
    @root2.name.should == "dc"
    @root2.namespace.prefix.should == "oai_dc"
    @root2.namespace.href.should == "http://www.openarchives.org/OAI/2.0/oai_dc/"

    @root3 = @xml3.xpath("//dc:title[. = 'MODIFIED COLLECTION TITLE']", :dc => "http://purl.org/dc/elements/1.1/").first.parent
    @root3.name.should == "qualifieddc"
    @root3.namespace.should == nil
    @root3.attr("xsi:noNamespaceSchemaLocation").should == "http://dublincore.org/schemas/xmls/qdc/2008/02/11/qualifieddc.xsd"
  end
end
