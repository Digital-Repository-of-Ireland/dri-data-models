# spec/metadata.dublin_core_audio_spec.rb
require 'spec_helper'

describe "DRI::Metadata::Properties" do

  before(:each) do
    @props = fixture("properties/properties_sample.xml")
    @ds = DRI::Metadata::Properties.from_xml(@props)
  end

  it "should expose system metadata for DRI digital objects" do
    @ds.status.should == ["published"]
    @ds.model_version.should == ["0.1.0"]
    @ds.resource_datastream.should == ["descMetadata", "masterContent"]

    @ds.resource(0).model_version.should == ["0.0.2"]
    @ds.resource(1).model_version.should == []

    @ds.resource(0).sha1.should == []
    @ds.resource(0).md5.should == []
    @ds.resource(1).sha1.should == ["FAKE_CHECKSUM_SHA1"]
    @ds.resource(1).md5.should == ["FAKE_CHECKSUM_MD5"]
  end

end
