# spec/metadata.dublin_core_audio_spec.rb
require 'spec_helper'

describe "DRI::Metadata::Properties" do

  before(:each) do
    @props = fixture("properties/properties_sample.xml")
    @ds = DRI::Metadata::Properties.from_xml(@props)
  end

  it "should expose system metadata for DRI digital objects" do
    @ds.status.should == ["published"]
    @ds.model_version.should == ["2.0.3"]
  end

end
