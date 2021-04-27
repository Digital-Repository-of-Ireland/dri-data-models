describe 'Marc' do
  context 'object methods' do
    before(:each) do
      @item_xml = fixture('marc/sandburg.xml')
      @item_null_xml = fixture('marc/sandburg_null.xml')

      @marc_item = DRI::Marc.new
      @marc_item.update_metadata DRI::Metadata::Marc.from_xml(@item_xml).to_xml

      @marc_item_null = DRI::Marc.new
      @marc_item_null.update_metadata DRI::Metadata::Marc.from_xml(@item_null_xml).to_xml

    end

    it 'should be a kind of DigitalObject' do
      @marc_item.should be_kind_of(DRI::DigitalObject)
    end

    it 'should have a marc datastream' do
      @marc_item.descMetadata.should be_kind_of(DRI::Metadata::Marc)
    end

    it "should expose the Marc components\' identifiers - mandatory fields" do
      @marc_item.marc_id.should == '0123456789'
      @marc_item.type.first.should == 'Language material'
      @marc_item.title.first.should == 'Arithmetic /'
      @marc_item.description.should == ["\n    1 v. (unpaged) :\n    ill. (some col.) ;\n    26 cm.\n  ", "\n    One Mylar sheet included in pocket.\n  ", "\n    A poem about numbers and their characteristics. Features anamorphic, or distorted, drawings which can be restored to normal by viewing from a particular angle or by viewing the image's reflection in the provided Mylar cone.\n  "]
      @marc_item.creator.should == ["\n    Sandburg, Carl,\n    1878-1967.\n  ", "\n    Rand, Ted,\n    ill.\n  "]
      @marc_item.rights.first.squish.should == 'Copyright Digital Repository of Ireland, 2013. Licensed under Creative Commons Attribution 4.0 International (CC BY 4.0).'
      @marc_item.date.should == ['c1993.', 'name=s1993; start=1993;']
    end

    it 'should validate the presence of title attribute' do
      @marc_item = DRI::Marc.new
      @no_title = fixture('marc/sandburg_no_title.xml')
      @marc_item.update_metadata DRI::Metadata::Marc.from_xml(@no_title).to_xml
      @marc_item.should_not be_valid
    end

    it 'should have namespaces removed from the marc datastream' do
      @marc_item = DRI::Marc.new
      @item_xml = fixture('marc/sandburg_qualified.xml')
      @marc_item.update_metadata DRI::Metadata::Marc.from_xml(@item_xml).to_xml

      marc_namespace = { 'xmlns:marc' => 'http://www.loc.gov/MARC21/slim' }
      expect(@marc_item.descMetadata.ng_xml.namespaces).not_to include(marc_namespace)
    end

    it 'should remove null values from creator metadata for index' do
      solr_doc = @marc_item_null.descMetadata.to_solr

      expect(solr_doc['creator_tesim'].any? { |v| /^null$/i.match(v) }).to eq false
    end

    after(:each) do
      @marc_item.delete unless @marc_item.new_record?
    end
  end
end
