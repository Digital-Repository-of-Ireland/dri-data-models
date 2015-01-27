# spec/modules/interchangeable_metadata_spec.rb
require 'spec_helper'

describe 'Batch' do

  before(:each) do
    @batch = DRI::Batch.new
  end

  xit "should have the ability to replace metadata" do
    @mods = (DRI::Metadata::Mods.new).to_xml
    @batch.datastreams.keys.should include("descMetadata")
    @batch.descMetadata.class.should == DRI::Metadata::QualifiedDublinCore
    @batch.update_metadata @mods
    @batch.descMetadata.class.should == DRI::Metadata::Mods
  end

  xit "should have the ability to test if the metadata is in a different class than what it originally loaded with" do
    # From a new class
    @mods = (DRI::Metadata::Mods.new).to_xml
    @dc = (DRI::Metadata::QualifiedDublinCore.new).to_xml
    @batch.datastreams.keys.should include("descMetadata")
    @batch.descMetadata.class.should == DRI::Metadata::QualifiedDublinCore
    @batch.update_metadata @mods
    @batch.descMetadata.class.should == DRI::Metadata::Mods
    @batch.has_metadata_class_changed?.should == true
    @batch.update_metadata @dc
    @batch.descMetadata.class.should == DRI::Metadata::QualifiedDublinCore
    @batch.has_metadata_class_changed?.should == false
  end

  xit "should not have the ability to replace non-archivist metadata with archivist metadata" do
    @ead = (DRI::Metadata::EncodedArchivalDescription.new).to_xml
    @batch.datastreams.keys.should include("descMetadata")
    @batch.descMetadata.class.should == DRI::Metadata::QualifiedDublinCore
    @batch.update_metadata @ead
    @batch.descMetadata.class.should == DRI::Metadata::QualifiedDublinCore
  end

  xit "should not have the ability to replace archivist metadata with non-archivist metadata" do
    @batch = DRI::Batch.new :desc_metadata_class => DRI::Metadata::EncodedArchivalDescription
    @batch.datastreams.keys.should include("descMetadata")
    @batch.descMetadata.class.should == DRI::Metadata::EncodedArchivalDescription
    @qdc = fixture("audios/dublin_core_audio_sample1.xml")
    @batch.update_metadata @qdc
    @batch.descMetadata.class.should == DRI::Metadata::EncodedArchivalDescription
  end

  xit "should have the ability to initialize a batch class with a specific DRI metadata class" do
    @batch = DRI::Batch.new :desc_metadata_class => DRI::Metadata::EncodedArchivalDescription
    @batch.datastreams.keys.should include("descMetadata")
    @batch.descMetadata.class.should == DRI::Metadata::EncodedArchivalDescription
  end

  xit "should default to using Qualified Dublin Core if Batch is new" do
    @batch.datastreams.keys.should include("descMetadata")
    @batch.descMetadata.class.should == DRI::Metadata::QualifiedDublinCore
  end

  after(:each) do
    unless @batch.new?
      @batch.delete
    end
  end

end
