# spec/modules/audio_spec.rb
require 'spec_helper'

describe DRI::Model::Audio do
  
  before(:each) do
    # This gives you a test article object that can be used in any of the tests
    @audio = DRI::Model::Audio.new
  end
  
  it "should have the specified datastreams" do
    # Check for descMetadata datastream with MODS in it
    @audio.datastreams.keys.should include("descMetadata")
    @audio.descMetadata.should be_kind_of DRI::Metadata::DublinCoreAudio
    # Check for rightsMetadata datastream
    @audio.datastreams.keys.should include("rightsMetadata")
    @audio.rightsMetadata.should be_kind_of Hydra::Datastream::RightsMetadata
  end

  it "should have the ability to add references to audio files" do
    @audio.add_file_reference("masterContent", {:url => "http://johndadlez.com/MP3/BTAS2_D1_45_Gotham.mp3", :mimeType => "audio/mpeg3"})
    @audio.datastreams.keys.should include("masterContent")
  end
  
  it "should have the attributes of a audio and support update_attributes" do
    attributes_hash = {
      "title" => "An Audio Title",
      "description" => "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
    "presenter" => ["Collins, Michael"],
    "guest" => ["DeValera, Eamonn", "Connolly, James"],
    "broadcast_date" => "1916-04-01"
    }
    
    @audio.update_attributes( attributes_hash )
    
    # These attributes have been marked "unique" in the call to delegate, which causes the results to be singular
    @audio.title.should == attributes_hash["title"]
    @audio.description.should == attributes_hash["description"]
    @audio.broadcast_date.should == attributes_hash["broadcast_date"]

    # These attributes have not been marked "unique" in the call to the delegate, which causes the results to be arrays
    @audio.presenter.should == attributes_hash["presenter"]
    @audio.guest.should == attributes_hash["guest"]    
  end
  
end
