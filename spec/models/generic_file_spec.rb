# spec/modules/generic_file.rb
require 'spec_helper'

describe GenericFile do
  
  before(:each) do
    # This gives you a test article object that can be used in any of the tests
    @file_asset = GenericFile.new
  end

  it "should have the ability to add references to audio files" do
    @file_asset.update_file_reference("masterContent", {:url => "http://johndadlez.com/MP3/BTAS2_D1_45_Gotham.mp3", :mimeType => "audio/mpeg3"})
    @file_asset.datastreams.keys.should include("content")
  end

  it "should not allow random files to be added" do
    @file_asset.update_file_reference("randomfile", {:url => "http://johndadlez.com/MP3/BTAS2_D1_45_Gotham.mp3", :mimeType => "audio/mpeg3"})
    @file_asset.datastreams.keys.should_not include("randomfile")
  end

  after(:each) do
    unless @file_asset.new?
      @file_asset.delete
    end
  end  

end
