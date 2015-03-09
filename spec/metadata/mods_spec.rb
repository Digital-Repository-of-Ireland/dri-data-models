require 'spec_helper'

describe 'Mods' do

  before(:each) do

    @collection_xml = fixture("mods/ns/mods-collection.xml")
    @mods_col = DRI::Mods.new :collection #DRI::Mods
    @mods_col.update_metadata DRI::Metadata::ModsCollection.from_xml(@collection_xml).to_xml
  end

  it "should expose the collection's identifiers" do
    @mods_col.mods_id_local.should == "MODS-ID-1234" # :multiple => false
    @mods_col.identifier.should == ["MODS-ID-1234", "http://example.org/collection/2#", "MS11182-030_1"]
    @mods_col.id_doi.should == ["MS11182-030_1"]
    @mods_col.id_uri.should == ["http://example.org/collection/2#"]
  end

  it "should use the type_of_resource attribute to determine whether is a collection" do
    @mods_col.is_collection?.should == true
    @mods_col.is_root_collection?.should == false
  end

  xit "should expose metadata fields recommended by the DRI Metadata Models Taskforce for indexing" do
  end

  it "should validate the presence of the title metadata field" do
    @mods_col.should be_valid
    @mods_col.title = [""]
    @mods_col.should_not be_valid
  end

  it "should validate the presence of the description metadata fields" do
    @mods_col.should be_valid
    @mods_col.abstract = [""]
    @mods_col.should_not be_valid
  end

  it "should validate the presence of the type attribute" do
    # <typeOfResource collection="yes" />
    @mods_col.should be_valid
    @mods_col.mods_type_collection = nil
    @mods_col.should_not be_valid
  end

  it "should validate the presence of term identifier with attribute type=local" do
    @mods_col.should be_valid
    @mods_col.mods_id_local = ""
    @mods_col.should_not be_valid
  end

  after(:each) do
    unless @mods_col.new_record?
      @mods_col.delete
    end
  end
end
