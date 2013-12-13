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

  xit "it should be invalid if there are incomplete mandatory fields" do
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
