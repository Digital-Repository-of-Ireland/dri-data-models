require 'spec_helper'

describe Batch do

  before(:each) do
    @series_xml = fixture("ead/component_series.xml")
    @file_xml = fixture("ead/component_file.xml")
    @ead_series = Batch.new :desc_metadata_class => DRI::Metadata::EncodedArchivalDescriptionComponent
    @ead_series.update_metadata DRI::Metadata::EncodedArchivalDescriptionComponent.from_xml(@series_xml).to_xml
    @ead_file = Batch.new :desc_metadata_class => DRI::Metadata::EncodedArchivalDescriptionComponent
    @ead_file.update_metadata DRI::Metadata::EncodedArchivalDescriptionComponent.from_xml(@file_xml).to_xml
  end

  it "should expose the EAD components' identifiers" do
    @ead_series.unitid.should == "KDW/TX"
    @ead_series.country_code.should == "IE"
    @ead_series.repository_code.should == "IE-DuNCA"
    @ead_file.unitid.should == "KDW/TX/01"
    @ead_file.country_code.should == "IE"
    @ead_file.repository_code.should == "IE-DuNCA"
  end

  it "should expose the level of the EAD component" do
    @ead_series.ead_level.should == "series"
    @ead_file.ead_level.should == "file"
  end

  it "should use the EAD component level to determine whether the component is a collection or not" do
    @ead_series.is_collection?.should == true
    @ead_series.is_root_collection?.should == false
    @ead_file.is_collection?.should == false
    @ead_file.is_root_collection?.should == false
  end

  xit "should expose metadata fields recommended by the DRI Metadata Models Taskforce for indexing" do
  end

  it "should validate the presence of the title metadata field" do
    @ead_file.title = ""
    @ead_file.should_not be_valid
  end

  it "should validate the presence of the description metadata fields" do
    @ead_file.scope_content = ""
    @ead_file.abstract = ""
    @ead_file.bioghist = ""
    @ead_file.should_not be_valid
  end

  it "should validate the presence of the genreform metadata field if component level is 'file'" do
    @ead_file.ead_level.should == "file"
    @ead_file.type = []
    @ead_file.should_not be_valid
  end

  it "should not validate the presence of the genreform metadata field if component level is not 'file'" do
    @ead_series.ead_level.should == "series"
    @ead_series.type = []
    @ead_series.should be_valid
  end

  it "should validate the presence of the level attribute" do
    @ead_file.ead_level = ""
    @ead_file.should_not be_valid
  end

  it "should validate the presence of an EAD unitid" do
    @ead_file.unitid = ""
    @ead_file.should_not be_valid
  end

  it "should validate the presence of the unitid countrycode attribute" do
    @ead_file.country_code = ""
    @ead_file.should_not be_valid
  end

  it "should validate the presence of the unitid repositorycode attribute" do
    @ead_file.repository_code = ""
    @ead_file.should_not be_valid
  end

  it "it should handle all variations of the EAD component node" do
    variations = ['c1', 'c2', 'c3', 'c4', 'c5', 'c6', 'c7', 'c8', 'c9', 'c10', 'c11', 'c12']
    variations.each do | curr_node_name |
      file_xml2 = fixture("ead/component_file.xml")
      curr_file = DRI::Metadata::EncodedArchivalDescriptionComponent.from_xml(file_xml2).to_xml
      curr_file = curr_file.gsub(/^<c/, '<'+curr_node_name)
      curr_file = curr_file.gsub(/c>$/, curr_node_name+'>')
      curr_batch = Batch.new :desc_metadata_class => DRI::Metadata::EncodedArchivalDescriptionComponent
      curr_batch.update_metadata curr_file
      curr_batch.unitid.should == "KDW/TX/01"
      curr_batch.ead_level.should == "file"
    end
  end

  xit "should be able to synchronize it's metadata with it's parent's metadata" do
  end

  after(:each) do
    unless @ead_file.new?
      @ead_file.delete
    end
    unless @ead_series.new?
      @ead_series.delete
    end
  end
end
