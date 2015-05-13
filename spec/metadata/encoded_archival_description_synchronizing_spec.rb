require 'spec_helper'

describe 'EncodedArchivalDescription' do

  before(:each) do
    @collection_xml = fixture("ead/collections/ead_collection_dtd.xml")
    @collection_modified_xml = fixture("ead/collections/ead_collection_modified_dtd.xml")
    @ead_collection = DRI::EncodedArchivalDescription.new :collection
    @ead_collection.update_metadata DRI::Metadata::EncodedArchivalDescription.from_xml(@collection_xml).to_xml
    @ead_collection.save
  end

  it "should add new children if it's metadata specifies this" do
    #@ead_collection.save
    @ead_collection.synchronize_children_to_metadata

    expected_nodes = { "KDW/RM" => { "prev" => nil, "next" => nil, "title" => "Related Material", "level" => "series" }}

    @ead_collection.governed_items.size.should == expected_nodes.length

    @ead_collection.governed_items.each do |curr_child|
        expected_nodes.has_key?(curr_child.identifier.first).should == true

        if (curr_child.previous_sibling == nil)
          expected_nodes[curr_child.identifier.first]["prev"].should == nil
        else
          expected_nodes[curr_child.identifier.first]["prev"].should == curr_child.previous_sibling.pid
        end

        if (curr_child.next_sibling == nil)
          expected_nodes[curr_child.identifier.first]["next"].should == nil
        else
          expected_nodes[curr_child.identifier.first]["next"].should == curr_child.next_sibling.pid
        end

        curr_child.title.should == [expected_nodes[curr_child.identifier.first]["title"]]
        curr_child.ead_level.should == expected_nodes[curr_child.identifier.first]["level"]
    end
  end

  it "should add new children if the batch is a EncodedArchivalDescriptionComponent" do
    # @ead_collection.save
    @ead_collection.synchronize_children_to_metadata
    ead_series = DRI::EncodedArchivalDescription.find(@ead_collection.governed_items[0].pid.to_s)
    ead_series.synchronize_children_to_metadata

    expected_nodes = { "KDW/RM/02" => { "prev" => nil, "next" => nil, "title" => "Ephemera", "level" => "file" }}

    ead_series.governed_items.size.should == expected_nodes.length

    ead_series.governed_items.each do |curr_child|
        expected_nodes.has_key?(curr_child.identifier.first).should == true

        if (curr_child.previous_sibling == nil)
          expected_nodes[curr_child.identifier.first]["prev"].should == nil
        else
          expected_nodes[curr_child.identifier.first]["prev"].should == curr_child.previous_sibling.pid
        end

        if (curr_child.next_sibling == nil)
          expected_nodes[curr_child.identifier.first]["next"].should == nil
        else
          expected_nodes[curr_child.identifier.first]["next"].should == curr_child.next_sibling.pid
        end

        curr_child.title.should == [ expected_nodes[curr_child.identifier.first]["title"]]
        curr_child.ead_level.should == expected_nodes[curr_child.identifier.first]["level"]
    end
  end

  it "should not modify a child's metadata if the updated child's metadata is identical to it's previous version" do
    # compare the datestamps of children that should not change
    # @ead_collection.save
    @ead_collection.synchronize_children_to_metadata
    datestamp = @ead_collection.governed_items[0].modified_date

    # running synchronize_children_to_metadata again should attempt to update the collection's children
    # with the same metadata as the last time it was run.
    @ead_collection.synchronize_children_to_metadata
    @ead_collection.governed_items[0].modified_date.should == datestamp
  end

  xit "should modify the order of it's children if it's metadata specifies this" do
  end

  xit "should delete children if they are not listed in the metadata" do
  end

  xit "should modify children's metadata if metadata specifies this" do
    # Load in the previously saved collection the new metadata (one component child has been added)
    new_collection = DRI::EncodedArchivalDescription.find_or_create(@ead_collection.pid.to_s)
    new_collection.update_metadata DRI::Metadata::EncodedArchivalDescription.from_xml(@collection_modified_xml).to_xml
    new_collection.save

    title = "Fake Invitation"
    solr_query = "title_tesim:\"#{title.to_s}\""
    new_obj = ActiveFedora::SolrService.query(solr_query, :defType => "edismax")
    new_obj.length.should == 1
  end

  after(:each) do
    if !@ead_collection.new_record?
      # Delete all descendants of @ead_collection and their generic files
      DRI::EncodedArchivalDescription.find(ActiveFedora::SolrService.solr_name('ancestor_id', :stored_searchable) => @ead_collection.pid.to_s).each do |obj|
        obj.generic_files.each do |file_obj|
          file_obj.delete
        end
        obj.delete
      end
      @ead_collection = DRI::EncodedArchivalDescription.find(@ead_collection.pid.to_s) #hmmm, have to do this before I delete otherwise I get a 404 error!
      @ead_collection.delete
    end
  end

end
