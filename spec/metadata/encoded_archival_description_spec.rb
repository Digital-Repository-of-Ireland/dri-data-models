require 'spec_helper'

describe 'EncodedArchivalDescription' do

  before(:each) do
    @series_xml = fixture("ead/component_series.xml")
    @file_xml = fixture("ead/component_file.xml")
    @item_xml = fixture("ead/component_item.xml")
    @collection_xml = fixture("ead/ead_collection.xml")
    @ead_collection = DRI::EncodedArchivalDescription.new :collection #DRI::Metadata::EncodedArchivalDescription
    @ead_collection.update_metadata DRI::Metadata::EncodedArchivalDescription.from_xml(@collection_xml).to_xml
    @ead_series = DRI::EncodedArchivalDescription.new :component #:desc_metadata_class => DRI::Metadata::EncodedArchivalDescriptionComponent
    @ead_series.update_metadata DRI::Metadata::EncodedArchivalDescriptionComponent.from_xml(@series_xml).to_xml
    @ead_file = DRI::EncodedArchivalDescription.new :component #:desc_metadata_class => DRI::Metadata::EncodedArchivalDescriptionComponent
    @ead_file.update_metadata DRI::Metadata::EncodedArchivalDescriptionComponent.from_xml(@file_xml).to_xml
    @ead_item = DRI::EncodedArchivalDescription.new :component #:desc_metadata_class => DRI::Metadata::EncodedArchivalDescriptionComponent
    @ead_item.update_metadata DRI::Metadata::EncodedArchivalDescriptionComponent.from_xml(@item_xml).to_xml
    
  end

  it "should expose the EAD components' identifiers" do
    @ead_collection.unitid.should == "IE/NIVAL KDW"
    @ead_collection.country_code.should == "IE"
    @ead_collection.repository_code.should == "IE-DuNIV"
    @ead_collection.identifier.should == ["KDW"]

    @ead_series.unitid.should == "KDW/RM"
    @ead_series.country_code.should == "IE"
    @ead_series.repository_code.should == "IE-DuNIV"
    @ead_series.identifier.should == ["RM"]

    @ead_file.unitid.should == "KDW/RM/02"
    @ead_file.country_code.should == "IE"
    @ead_file.repository_code.should == "IE-DuNIV"
    @ead_file.identifier.should == ["02"]

    @ead_item.unitid.should == "KDW/RM/02/04"
    @ead_item.country_code.should == "IE"
    @ead_item.repository_code.should == "IE-DuNIV"
    @ead_item.identifier.should == ["04"]
  end

  it "should expose the level of the EAD component" do
    @ead_collection.ead_level.should == "fonds"
    @ead_series.ead_level.should == "series"
    @ead_file.ead_level.should == "file"
    @ead_item.ead_level.should == "item"
  end

  it "should use the EAD component level to determine whether the component is a collection or not" do
    @ead_collection.is_collection?.should == true
    @ead_collection.is_root_collection?.should == false
    @ead_series.is_collection?.should == true
    @ead_series.is_root_collection?.should == false
    @ead_file.is_collection?.should == true
    @ead_file.is_root_collection?.should == false
    @ead_item.is_collection?.should == false
    @ead_item.is_root_collection?.should == false
  end

  xit "should expose metadata fields recommended by the DRI Metadata Models Taskforce for indexing" do
  end

  it "should validate the presence of the title metadata field" do
    @ead_collection.should be_valid
    @ead_collection.title = ""
    @ead_collection.should_not be_valid

    @ead_series.should be_valid
    @ead_series.title = ""
    @ead_series.should_not be_valid

    @ead_file.should be_valid
    @ead_file.title = ""
    @ead_file.should_not be_valid

    @ead_item.should be_valid
    @ead_item.title = ""
    @ead_item.should_not be_valid
  end

  it "should validate the presence of the description metadata fields" do
    @ead_collection.should be_valid
    @ead_collection.scope_content = ""
    @ead_collection.abstract = ""
    @ead_collection.bioghist = ""
    @ead_collection.should_not be_valid

    @ead_series.should be_valid
    @ead_series.scope_content = ""
    @ead_series.abstract = ""
    @ead_series.bioghist = ""
    @ead_series.dao_desc = ""
    @ead_series.should_not be_valid

    @ead_file.should be_valid
    @ead_file.scope_content = ""
    @ead_file.abstract = ""
    @ead_file.bioghist = ""
    @ead_file.dao_desc = ""
    @ead_file.should_not be_valid

    @ead_item.should be_valid
    @ead_item.scope_content = ""
    @ead_item.abstract = ""
    @ead_item.bioghist = ""
    @ead_item.dao_desc = ""
    @ead_item.should_not be_valid
  end

  it "should validate the presence of the level attribute" do
    @ead_collection.should be_valid
    @ead_collection.ead_level = ""
    @ead_collection.should_not be_valid

    @ead_series.should be_valid
    @ead_series.ead_level = ""
    @ead_series.should_not be_valid

    @ead_file.should be_valid
    @ead_file.ead_level = ""
    @ead_file.should_not be_valid

    @ead_item.should be_valid
    @ead_item.ead_level = ""
    @ead_item.should_not be_valid
  end

  it "should validate the presence of an EAD identifier" do
    @ead_collection.should be_valid
    @ead_collection.unitid = ""
    @ead_collection.should_not be_valid

    @ead_series.should be_valid
    @ead_series.unitid = ""
    @ead_series.should_not be_valid

    @ead_file.should be_valid
    @ead_file.unitid = ""
    @ead_file.should_not be_valid

    @ead_item.should be_valid
    @ead_item.unitid = ""
    @ead_item.should_not be_valid
  end

  it "should validate the presence of the unitid countrycode attribute" do
    @ead_collection.should be_valid
    @ead_collection.country_code = ""
    @ead_collection.should_not be_valid

    @ead_series.should be_valid
    @ead_series.country_code = ""
    @ead_series.should_not be_valid

    @ead_file.should be_valid
    @ead_file.country_code = ""
    @ead_file.should_not be_valid

    @ead_item.should be_valid
    @ead_item.country_code = ""
    @ead_item.should_not be_valid
  end

  it "should validate the presence of the unitid repositorycode attribute" do
    @ead_collection.should be_valid
    @ead_collection.repository_code = ""
    @ead_collection.should_not be_valid

    @ead_series.should be_valid
    @ead_series.repository_code = ""
    @ead_series.should_not be_valid

    @ead_file.should be_valid
    @ead_file.repository_code = ""
    @ead_file.should_not be_valid

    @ead_item.should be_valid
    @ead_item.repository_code = ""
    @ead_item.should_not be_valid
  end

  it "should handle all variations of the EAD component node" do
    variations = ['c1', 'c2', 'c3', 'c4', 'c5', 'c6', 'c7', 'c8', 'c9', 'c10', 'c11', 'c12']
    variations.each do | curr_node_name |
      file_xml2 = fixture("ead/component_file.xml")
      curr_file = DRI::Metadata::EncodedArchivalDescriptionComponent.from_xml(file_xml2).to_xml
      curr_file = curr_file.gsub(/^<c/, '<'+curr_node_name)
      curr_file = curr_file.gsub(/c>$/, curr_node_name+'>')
      curr_batch = DRI::EncodedArchivalDescription.new :component
      curr_batch.update_metadata curr_file
      curr_batch.unitid.should == "KDW/RM/02"
      curr_batch.ead_level.should == "file"
    end
  end

  after(:each) do
    unless @ead_item.new_record?
      @ead_item.generic_files.each do |file_obj|
          file_obj.delete
      end
      @ead_item.delete
    end
    unless @ead_file.new_record?
      @ead_file.delete
    end
    unless @ead_series.new_record?
      @ead_series.delete
    end
    unless @ead_collection.new_record?
      @ead_collection.delete
    end
  end
end
