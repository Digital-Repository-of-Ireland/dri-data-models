# spec/modules/collection_spec.rb
require 'spec_helper'


describe DRI::Model::Collection do
  
  before(:each) do
    # This gives you a test article object that can be used in any of the tests
    @collection = DRI::Model::Collection.new

    @attributes_hash = {
      "title" => "The Collection Title",
      "description" => "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
      "publisher" => "NUI Maynooth"
    }

  end

  it "should have the specified datastreams" do
    # Check for descMetadata datastream with MODS in it
    @collection.datastreams.keys.should include("descMetadata")
    @collection.descMetadata.should be_kind_of DRI::Metadata::DublinCoreCollection

    # Check for rightsMetadata datastream
    @collection.datastreams.keys.should include("rightsMetadata")
    @collection.rightsMetadata.should be_kind_of Hydra::Datastream::RightsMetadata

    # Check for datastream that contains the access rights for the entire collection
    @collection.datastreams.keys.should include("defaultRights")
    @collection.defaultRights.should be_kind_of Hydra::Datastream::InheritableRightsMetadata
  end

  it "should not be valid with no metadata" do
    @collection.should_not be_valid
  end

  it "should be able to govern digital objects" do
    @child1 = DRI::Model::Audio.create
    @child1.title = "CHILD ONE"

    @child2 = DRI::Model::Pdfdoc.create
    @child2.title = "CHILD TWO"

    @collection.governed_items.length.should == 0
    @collection.governed_items << @child1
    @collection.governed_items.length.should == 1
    @collection.governed_items << @child2
    @collection.governed_items.length.should == 2
    @collection.governed_items[0] = @child1.title = "CHILD ONE"
    @collection.governed_items[1] = @child2.title = "CHILD TWO"
  end

  it "should act as a collection to digital objects" do
    @child1 = DRI::Model::Audio.create
    @child1.title = "CHILD ONE"

    @child2 = DRI::Model::Pdfdoc.create
    @child2.title = "CHILD TWO"

    @collection.items.length.should == 0
    @collection.items << @child1
    @collection.items.length.should == 1
    @collection.items << @child2
    @collection.items.length.should == 2
    @collection.items[0] = @child1.title = "CHILD ONE"
    @collection.items[1] = @child2.title = "CHILD TWO"
  end

  it "should create a valid collection object when valid metadata is ingested" do
    # From ingestion
    @dc = fixture("collections/dublin_core_collection_sample.xml")
    @ds = DRI::Metadata::DublinCoreCollection.from_xml(@dc)
    @collection2 = DRI::Model::Collection.new
    @collection2.datastreams["descMetadata"] = @ds
    @collection2.should be_valid
  end
     
  it "should have the attributes of a collection and support update_attributes" do
    @collection.update_attributes( @attributes_hash )
    
    # These attributes have been marked "unique" in the call to delegate, which causes the results to be singular
    @collection.title.class.to_s.should == 'String'
    @collection.description.class.to_s.should == 'String'
    @collection.publisher.class.to_s.should == 'String'

    # The value should match what was set in the attributes_hash above
    @collection.title.should == @attributes_hash["title"]
    @collection.description.should == @attributes_hash["description"]
    @collection.publisher.should == @attributes_hash["publisher"]
 
  end

  it "should validate the presence of the title metadata field" do
    # From ingestion
    @dc = fixture("collections/dublin_core_collection_notitle_sample.xml")
    @ds = DRI::Metadata::DublinCoreCollection.from_xml(@dc)
    @collection = DRI::Model::Collection.new
    @collection.datastreams["descMetadata"] = @ds
    @collection.should_not be_valid

    # From variable assignment
    @attributes_hash["title"] = ""

    @collection.update_attributes( @attributes_hash )

    @collection.should_not be_valid

  end


end
