require 'spec_helper'
require 'nokogiri'

describe 'Batch' do

  before(:each) do
    @item_xml = fixture("marc/sandburg.xml")
    @marc_item = Batch.new :desc_metadata_class => DRI::Metadata::Marc
    @marc_item.update_metadata DRI::Metadata::Marc.from_xml(@item_xml).to_xml
  end
  context "general behaviors" do
    it "should be a kind of Batch" do
      @marc_item.should be_kind_of(Batch)
    end

    it "datastrea: descMetadata should be a kind of OmDatastream" do
      @marc_item.descMetadata.should be_kind_of(ActiveFedora::OmDatastream)
    end

    after(:each) do
      unless @marc_item.new_record?
        @marc_item.delete
      end

    end
  end

  MARC_NS = 'http://www.loc.gov/MARC21/slim'

  context "creating new marc xml" do
    subject { DRI::Metadata::Marc.new }

    it "should have an xml_template method returning desired xml" do
      empty_xml = subject.class.xml_template
      empty_xml.should be_a_kind_of(Nokogiri::XML::Document)
      empty_xml.collect_namespaces["xmlns:marc"].should eq(MARC_NS)
      empty_xml.children.first.name.should eq("collection")
    end
  end
end
