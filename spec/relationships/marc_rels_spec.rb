require 'spec_helper'

describe 'Marc' do

  # Before each test create test objects
  before(:each) do
    @nccb0_xml = fixture("relationships/marc/nccb0.xml")
    @nccb1_xml = fixture("relationships/marc/nccb1.xml")
    @nccb2_xml = fixture("relationships/marc/nccb2.xml")
    @nccb3_xml = fixture("relationships/marc/nccb3.xml")
    @nccb0 = DRI::Marc.new
    @nccb1 = DRI::Marc.new
    @nccb2 = DRI::Marc.new
    @nccb3 = DRI::Marc.new
    @nccb0.update_metadata DRI::Metadata::Marc.from_xml(@nccb0_xml).to_xml
    @nccb1.update_metadata DRI::Metadata::Marc.from_xml(@nccb1_xml).to_xml
    @nccb2.update_metadata DRI::Metadata::Marc.from_xml(@nccb2_xml).to_xml
    @nccb3.update_metadata DRI::Metadata::Marc.from_xml(@nccb3_xml).to_xml

    @nccb0.save

    @nccb1.governing_collection = @nccb0
    @nccb1.save
    @nccb2.governing_collection = @nccb0
    @nccb2.save
    @nccb3.governing_collection = @nccb0
    @nccb3.save
  end

  it "should add relationship relation, is_version_of and is_format_of" do
    md_relationships_hash = @nccb1.get_relationships_records

    added_rels = [DRI::Marc.find(md_relationships_hash[:related].first).marc_id,
        DRI::Marc.find(md_relationships_hash[:is_format].first).marc_id,
        DRI::Marc.find(md_relationships_hash[:is_version].first).marc_id]

    added_rels.should =~ ["nccb3", "nccb2", "nccb0"]
  end

  after(:each) do
    unless @nccb0.new_record?
      #@nccb0.delete
    end
  end

end