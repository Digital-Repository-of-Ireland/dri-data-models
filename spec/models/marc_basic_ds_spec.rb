require 'nokogiri'

describe 'Marc' do
  before(:each) do
    @item_xml = fixture('marc/sandburg.xml')
    @marc_item = DRI::Marc.new
    @marc_item.update_metadata DRI::Metadata::Marc.from_xml(@item_xml).to_xml
  end
  context 'general behaviors' do
    it 'should be a kind of Base' do
      @marc_item.should be_kind_of(DRI::Base)
    end

    it 'datastream: descMetadata should be a kind of OmDatastream' do
      @marc_item.descMetadata.should be_kind_of(DRI::OmDatastream)
    end

    after(:each) do
      @marc_item.delete unless @marc_item.new_record?
    end
  end

  MARC_NS = 'http://www.loc.gov/MARC21/slim'

  context 'creating new marc xml' do
    subject { DRI::Metadata::Marc.new }

    it 'should have an xml_template method returning desired xml' do
      empty_xml = subject.class.xml_template
      empty_xml.should be_a_kind_of(Nokogiri::XML::Document)
      empty_xml.collect_namespaces['xmlns:marc'].should eq(MARC_NS)
      empty_xml.children.first.name.should eq('record')
    end
  end
end
