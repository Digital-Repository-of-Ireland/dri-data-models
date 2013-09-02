# spec/modules/digital_object_spec.rb
require 'spec_helper'


describe DRI::Model::DigitalObject do
  
  before(:each) do

    @audio_hash = {
      "title" => "The Audio Title",
      "rights" => "This is a statement about the rights associated with this object",
      "presenter" => ["Collins, Michael"],
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

    @pdf_hash = {
      "title" => "The PDF Title",
      "rights" => "This is a statement about the rights associated with this object",
      "author" => ["Collins, Michael"],
      "editor" => ["Valera, Eamon, de", "Connolly, James"],
      "language" => "ga",
      "description" => "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
      "creation_date" => "1916-01-01",
      "source" => ["CD nnn nuig"],
      "geographical_coverage" => ["Dublin"],
      "temporal_coverage" => ["1900s"],
      "subject" => ["Ireland","something else"]
    }

  end

  it "should create an audio object" do
    @class = DRI::Model::DigitalObject.construct(:audio, @audio_hash)
    @class.should be_kind_of DRI::Model::Audio
  end

  it "should create a pdf object" do
    @class = DRI::Model::DigitalObject.construct(:pdfdoc, @pdf_hash)
    @class.should be_kind_of DRI::Model::Pdfdoc
  end

  it "should create an audio object with the correct attributes" do
    @attributes_hash = @audio_hash
    @audio = DRI::Model::DigitalObject.construct(:audio, @attributes_hash)
   
    # These attributes have been marked "unique" in the call to delegate, which causes the results to be singular
    @audio.title.class.to_s.should == 'String'
    @audio.rights.class.to_s.should == 'String'
    @audio.description.class.to_s.should == 'String'
    @audio.language.class.to_s.should == 'String'
    @audio.broadcast_date.class.to_s.should == 'String'
    @audio.creation_date.class.to_s.should == 'String'

    # These attributes have not been marked "unique" in the call to the delegate, which causes the results to be arrays
    @audio.presenter.class.to_s.should == 'Array'
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
    @audio.presenter.should == @attributes_hash["presenter"]
    @audio.guest.should == @attributes_hash["guest"]
    @audio.subject.should == @attributes_hash["subject"]
    @audio.source.should == @attributes_hash["source"]
    @audio.geographical_coverage.should == @attributes_hash["geographical_coverage"]
    @audio.temporal_coverage.should == @attributes_hash["temporal_coverage"]
  end 

  it "should create a pdf object with the correct attributes" do
    @attributes_hash = @pdf_hash
    @pdfdoc = DRI::Model::DigitalObject.construct(:pdfdoc, @pdf_hash)

    # These attributes have been marked "unique" in the call to delegate, which causes the results to be singular
    @pdfdoc.title.class.to_s.should == 'String'
    @pdfdoc.rights.class.to_s.should == 'String'
    @pdfdoc.description.class.to_s.should == 'String'
    @pdfdoc.language.class.to_s.should == 'String'
    @pdfdoc.creation_date.class.to_s.should == 'String'

    # These attributes have not been marked "unique" in the call to the delegate, which causes the results to be arrays
    @pdfdoc.author.class.to_s.should == 'Array'
    @pdfdoc.editor.class.to_s.should == 'Array'
    @pdfdoc.subject.class.to_s.should == 'Array'
    @pdfdoc.source.class.to_s.should == 'Array'
    @pdfdoc.geographical_coverage.class.to_s.should == 'Array'
    @pdfdoc.temporal_coverage.class.to_s.should == 'Array'

    # The value should match what was set in the attributes_hash above
    @pdfdoc.title.should == @attributes_hash["title"]
    @pdfdoc.rights.should == @attributes_hash["rights"]
    @pdfdoc.description.should == @attributes_hash["description"]
    @pdfdoc.creation_date.should == @attributes_hash["creation_date"]
    @pdfdoc.language.should == @attributes_hash["language"]
    @pdfdoc.author.should == @attributes_hash["author"]
    @pdfdoc.editor.should == @attributes_hash["editor"]
    @pdfdoc.subject.should == @attributes_hash["subject"]
    @pdfdoc.source.should == @attributes_hash["source"]
    @pdfdoc.geographical_coverage.should == @attributes_hash["geographical_coverage"]
    @pdfdoc.temporal_coverage.should == @attributes_hash["temporal_coverage"]
  end
  
end
