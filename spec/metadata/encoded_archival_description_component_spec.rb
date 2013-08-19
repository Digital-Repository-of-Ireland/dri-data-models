# spec/metadata/encoded_archival_description_component_spec.rb
require 'spec_helper'

describe "DRI::Metadata::EncodedArchivalDescriptionComponent" do

  it "is implemented but pending" do
    pending("updating class to NIVAL data")
    this_should_not_get_executed
  end

  #before(:each) do
  #  @component_xml = fixture("audios/ead_component_sample1.xml")
  #  @ds = DRI::Metadata::EncodedArchivalDescriptionComponent.from_xml(@component_xml)
  #end

  #it "should expose common metadata info for audio" do
  #  @ds.title.should == ["SAMPLE AUDIO TITLE"]
  #  @ds.description.should == ["SAMPLE DESCRIPTION"]
  #  @ds.language.should == ["en"]
  #  @ds.subject.should == ["subject1","subject2","subject3"]
  #  @ds.subject(0).should == ["subject1"]
  #end

  #it "should expose specific audio metadata" do
  #  @ds.broadcast_date == ["2000-01-01"]
  #  @ds.presenter.should == ["DeValera, Eamonn"]
  #  @ds.guest.should == ["Collins, Michael", "Connolly, James"]
  #end

end
