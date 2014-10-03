require 'spec_helper'

describe 'Batch' do

  before(:each) do
    @item_xml = fixture("marc/sandburg.xml")
    @marc_item = Batch.new :desc_metadata_class => DRI::Metadata::Marc
    @marc_item.update_metadata DRI::Metadata::Marc.from_xml(@item_xml).to_xml

  end

  it "should be a kind of Batch" do
    @marc_item.should be_kind_of(Batch)
  end

  it "should expose the Marc components' identifiers - mandatory fields" do
    @marc_item.type.first.should == "01142cam  2200301 a 4500"
    @marc_item.title.first.should == "Arithmetic /"
    @marc_item.description.should ==   ["\n      1 v. (unpaged) :\n      ill. (some col.) ;\n      26 cm.\n    ", "\n      One Mylar sheet included in pocket.\n    ", "\n      A poem about numbers and their characteristics. Features anamorphic, or distorted, drawings which can be restored to normal by viewing from a particular angle or by viewing the image's reflection in the provided Mylar cone.\n    "]
    @marc_item.creator.should ==   ["\n      Sandburg, Carl,\n      1878-1967.\n    ", "\n      Rand, Ted,\n      ill.\n    "]
    @marc_item.rights.first.squish.should == "Copyright Digital Repository of Ireland, 2013. Licensed under Creative Commons Attribution 4.0 International (CC BY 4.0)."
    @marc_item.creation_date.should == ["920219s1993    caua   j      000 0 eng  ", "c1993."]
  end

  it "should validate the presence of title attribute" do
    @marc_item.should be_valid
    @marc_item.title = [""]
    @marc_item.should_not be_valid
  end
  it "should validate the presence of type attribute" do
    @marc_item.should be_valid
    @marc_item.type = [""]
    @marc_item.should_not be_valid
  end
  it "should validate the presence of description attribute" do
    @marc_item.should be_valid
    @marc_item.description = [""]
    @marc_item.should_not be_valid
  end
  it "should validate the presence of creator attribute" do
    @marc_item.should be_valid
    @marc_item.creator = [""]
    @marc_item.should_not be_valid
  end
  it "should validate the presence of rights attribute" do
    @marc_item.should be_valid
    @marc_item.rights = [""]
    @marc_item.should_not be_valid
  end
  it "should validate the presence of creation_date attribute" do
    @marc_item.should be_valid
    @marc_item.creation_date = [""]
    @marc_item.should_not be_valid
  end

  after(:each) do
    unless @marc_item.new_record?
      @marc_item.delete
    end

  end
end
