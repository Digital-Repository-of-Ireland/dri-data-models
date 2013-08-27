# spec/modules/audio_spec.rb
require 'spec_helper'


describe DRI::Model::Audio do
  
  before(:each) do
    # This gives you a test article object that can be used in any of the tests
    @audio = DRI::Model::Audio.new

    @attributes_hash = {
      "title" => "The Audio Title",
      "rights" => "This is a statement about the rights associated with this object",
      "role_hst" => ["Collins, Michael"],
      "role_pro" => ["Collins, Michael"],
      "guest" => ["Valera, Eamon, de", "Connolly, James"],
      "language" => "ga",
      "description" => "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
      "broadcast_date" => "1916-04-01",
      "creation_date" => "1916-01-01",
      "source" => ["CD nnn nuig"],
      "geographical_coverage" => ["Dublin"],
      "temporal_coverage" => ["1900s"],
      "subject" => ["Ireland","something else"]
    }

  end

  it "should have the specified datastreams" do
    # Check for descMetadata datastream with MODS in it
    @audio.datastreams.keys.should include("descMetadata")
    @audio.descMetadata.should be_kind_of DRI::Metadata::DublinCoreAudio
    # Check for rightsMetadata datastream
    @audio.datastreams.keys.should include("rightsMetadata")
    @audio.rightsMetadata.should be_kind_of Hydra::Datastream::RightsMetadata
    # Check for properties datastream
    @audio.datastreams.keys.should include("properties")
    @audio.properties.should be_kind_of DRI::Metadata::Properties
  end

  it "should have the ability to add references to audio files" do
    @audio.add_file_reference("masterContent", {:url => "http://johndadlez.com/MP3/BTAS2_D1_45_Gotham.mp3", :mimeType => "audio/mpeg3"})
    @audio.datastreams.keys.should include("masterContent")
  end

  it "should not allow random files to be added" do
    @audio.add_file_reference("randomfile", {:url => "http://johndadlez.com/MP3/BTAS2_D1_45_Gotham.mp3", :mimeType => "audio/mpeg3"})
    @audio.datastreams.keys.should_not include("randomfile")
  end

  it "should not be valid with no metadata" do
    @audio.should_not be_valid
  end

  it "should create a valid audio object when valid metadata is ingested" do
    # From ingestion
    @dc = fixture("audios/dublin_core_audio_sample1.xml")
    @ds = DRI::Metadata::DublinCoreAudio.from_xml(@dc)
    @audio2 = DRI::Model::Audio.new
    @audio2.datastreams["descMetadata"] = @ds
    @audio2.should be_valid
  end

  it "the status property should be set as 'draft' when a new Audio object is created" do
    @audio = DRI::Model::Audio.new
    @audio.status.should == "draft"
  end
     
  it "should have the attributes of a audio and support update_attributes" do
    @audio.update_attributes( @attributes_hash )
    
    # These attributes have been marked "unique" in the call to delegate, which causes the results to be singular
    @audio.title.class.to_s.should == 'String'
    @audio.rights.class.to_s.should == 'String'
    @audio.description.class.to_s.should == 'String'
    @audio.language.class.to_s.should == 'String'
    @audio.broadcast_date.class.to_s.should == 'String'
    @audio.creation_date.class.to_s.should == 'String'

    # These attributes have not been marked "unique" in the call to the delegate, which causes the results to be arrays
    @audio.role_hst.class.to_s.should == 'Array'
    @audio.role_pro.class.to_s.should == 'Array'
    @audio.guest.class.to_s.should == 'Array'
    @audio.subject.class.to_s.should == 'Array'
    @audio.source.class.to_s.should == 'Array'
    @audio.geographical_coverage.class.to_s.should == 'Array'
    @audio.temporal_coverage.class.to_s.should == 'Array'

    # The value should match what was set in the attributes_hash above
    @audio.title.should == @attributes_hash["title"]
    @audio.rights.should == @attributes_hash["rights"]
    @audio.description.should == @attributes_hash["description"]
    @audio.broadcast_date.should == @attributes_hash["broadcast_date"]
    @audio.creation_date.should == @attributes_hash["creation_date"]
    @audio.language.should == @attributes_hash["language"]
    @audio.role_pro.should == @attributes_hash["role_hst"]
    @audio.presenter.should == @attributes_hash["role_hst"]
    @audio.role_hst.should == @attributes_hash["role_pro"]
    @audio.producer.should == @attributes_hash["role_pro"]
    @audio.guest.should == @attributes_hash["guest"]    
    @audio.subject.should == @attributes_hash["subject"]
    @audio.source.should == @attributes_hash["source"]
    @audio.geographical_coverage.should == @attributes_hash["geographical_coverage"]
    @audio.temporal_coverage.should == @attributes_hash["temporal_coverage"]
 
  end

  it "should validate the presence of the title metadata field" do
    # From ingestion
    @dc = fixture("audios/dublin_core_audio_notitle_sample.xml")
    @ds = DRI::Metadata::DublinCoreAudio.from_xml(@dc)
    @audio2 = DRI::Model::Audio.new
    @audio2.datastreams["descMetadata"] = @ds
    @audio2.should_not be_valid

    # From variable assignment
    @attributes_hash["title"] = ""

    @audio.update_attributes( @attributes_hash )

    @audio.should_not be_valid

  end

  it "should validate the presence of the rights metadata field" do
    # From ingestion
    @dc = fixture("audios/dublin_core_audio_norights_sample.xml")
    @ds = DRI::Metadata::DublinCoreAudio.from_xml(@dc)
    @audio2 = DRI::Model::Audio.new
    @audio2.datastreams["descMetadata"] = @ds
    @audio2.should_not be_valid

    # From variable assignment
    @attributes_hash["rights"] = ""

    @audio.update_attributes( @attributes_hash )

    @audio.should_not be_valid

  end

  after(:each) do
    unless @audio.class != ActiveFedora::UnsavedDigitalObject
      @audio.delete
    end
  end

  it "should have type 'Sound'" do
  end    

end
