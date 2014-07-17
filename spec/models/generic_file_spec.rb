# spec/modules/generic_file.rb
require 'spec_helper'

describe 'GenericFile' do
  
  before(:each) do
    # This gives you a test article object that can be used in any of the tests
    @file_asset = GenericFile.new
  end

  it "should have the ability to add references to audio files" do
    @file_asset.update_file_reference("content", {:url => "http://johndadlez.com/MP3/BTAS2_D1_45_Gotham.mp3", :mimeType => "audio/mpeg3"})
    @file_asset.content.dsLocation.should == "http://johndadlez.com/MP3/BTAS2_D1_45_Gotham.mp3"
    @file_asset.content.mimeType.should == "audio/mpeg3"
    @file_asset.content.controlGroup.should == "R"
  end

  it "should not have the ability to create new datastreams when updating a file reference" do
    @file_asset.update_file_reference("randomfile", {:url => "http://johndadlez.com/MP3/BTAS2_D1_45_Gotham.mp3", :mimeType => "audio/mpeg3"})
    @file_asset.datastreams.keys.should_not include("randomfile")
  end

  it "should have a characterize method" do
    @file_asset.should respond_to?(:characterize)
  end

  #it "should validate the existence of file content" do
  #  @file_asset.should_not be_valid
  #  @file_asset.update_file_reference("randomfile", {:url => "http://johndadlez.com/MP3/BTAS2_D1_45_Gotham.mp3", :mimeType => "audio/mpeg3"})
  #  @file_asset.should be_valid
  #end

  after(:each) do
    unless @file_asset.new_record?
      @file_asset.delete
    end
  end  

end
