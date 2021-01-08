describe 'DRI::Metadata::Properties' do
  before(:each) do
    @props = fixture('properties/properties_sample.xml')
    @ds = DRI::Metadata::Properties.from_xml(@props)
  end

  it 'should expose system metadata for DRI digital objects' do
    expect(@ds.model_version).to match_array(['0.1.0'])
  end
end
