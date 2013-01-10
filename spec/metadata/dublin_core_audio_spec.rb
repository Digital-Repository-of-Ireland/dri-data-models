# spec/metadata.dublin_core_audio_spec.rb
require 'spec_helper'

describe "DRI::Metadata::DublinCoreAudio" do
  before(:each) do
    @dc = fixture("dublin_core_audio_sample1.xml")
    @ds = DRI::Metadata::DublinCoreAudio.from_xml(@dc)
  end
  it "should expose common metadata info for audio" do
    @ds.title.should == ["SAMPLE AUDIO TITLE"]
    @ds.description.should == ["SAMPLE DESCRIPTION"]
    @ds.language.should == ["en"]
    @ds.subject.should == ["subject1","subject2","subject3"]
    @ds.subject(0).should == ["subject1"]
  end
  it "should expose specific audio metadata" do
    @ds.broadcast_date == ["2000-01-01"]
    @ds.presenter.should == ["DeValera, Eamonn"]
    @ds.guest.should == ["Collins, Michael", "Connolly, James"]
  end
end
