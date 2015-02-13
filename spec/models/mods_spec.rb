require 'spec_helper'

describe 'Mods' do
  # Before each test create test objects
  before(:each) do
    @mods_xml = fixture("mods/ns/sample-mods.xml")
    @mods_record = DRI::Mods.new :record
    @mods_record.update_metadata DRI::Metadata::Mods.from_xml(@mods_xml).to_xml
  end

  # MODS Object Tests
  it "should be a kind of Batch" do
    @mods_record.should be_kind_of(DRI::Batch)
  end

  it "should have a mods datastream" do
    @mods_record.descMetadata.should be_kind_of(DRI::Metadata::Mods)
  end

  xit "should have namespaces removed from the mods datastream" do
    mods_ns = {"xmlns:mods" => "http://www.loc.gov/mods/v3"}
    expect(@mods_record.descMetadata.ng_xml.namespaces).not_to include(mods_ns)
  end

  # DRI elements tests

  # Title
  it "should validate the presence of title attribute" do
    @mods_record = DRI::Mods.new :record
    @no_title = fixture("mods/ns/sample-mods-notitle.xml")
    @mods_record.update_metadata DRI::Metadata::Mods.from_xml(@no_title).to_xml
    @mods_record.should_not be_valid
  end

  xit "should add create mods records if modsCollection is used in metadata" do
    @mods_record = DRI::Mods.new :record

  end

  # After each test clean-up
  after(:each) do
    if !@mods_record.new_record?
      @mods_record.delete
    end
  end
end