require 'spec_helper'

describe 'EncodedArchivalDescription' do
  # Before each test create test objects
  before(:each) do
    @header_xml = fixture("ead/collections/ead_header_dtd.xml")
    @ead_header = DRI::EncodedArchivalDescription.new :collection
    @ead_header.update_metadata DRI::Metadata::EncodedArchivalDescription.from_xml(@header_xml).to_xml
  end

  # EAD Object Tests
  it "should be a kind of Batch" do
    @ead_header.should be_kind_of(DRI::Batch)
  end

  it "should have an ead datastream" do
    @ead_header.descMetadata.should be_kind_of(DRI::Metadata::EncodedArchivalDescription)
  end

  xit "should have namespaces removed from the ead datastream" do
    ead_namespace = {"xmlns:ead" => "urn:isbn:1-931666-22-9"}
    expect(@ead_header.descMetadata.ng_xml.xpath("/ead:ead", ead_namespace)).to be_empty
  end

  # DRI elements tests

  # Title
  it "should validate the presence of title attribute" do
    @ead_header = DRI::EncodedArchivalDescription.new :collection
    @no_title = fixture("ead/collections/ead_header_no_title.xml")
    @ead_header.update_metadata DRI::Metadata::EncodedArchivalDescription.from_xml(@no_title).to_xml
    @ead_header.should_not be_valid
  end

  # After each test clean-up
  after(:each) do
    if !@ead_header.new_record?
      @ead_header.delete
    end
  end
end