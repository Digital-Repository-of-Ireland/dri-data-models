describe 'GenericFile' do
  before(:each) do
    # This gives you a test article object that can be used in any of the tests
    @file_asset = DRI::GenericFile.new
  end

  it 'should have a characterize method' do
    @file_asset.should respond_to?(:characterize)
  end

  after(:each) do
    unless @file_asset.new_record?
      @file_asset.delete
    end
  end
end
