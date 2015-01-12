require 'spec_helper'

describe 'Batch' do

  before(:each) do
    @collection_xml = fixture("ead/ead_collection.xml")
    @ead_collection = Batch.new :desc_metadata_class => DRI::Metadata::EncodedArchivalDescription
    @ead_collection.update_metadata DRI::Metadata::EncodedArchivalDescription.from_xml(@collection_xml).to_xml
  end

  xit "should add new children if it's metadata specifies this" do
    @ead_collection.save
    @ead_collection.synchronize_children_to_metadata

    expected_nodes = { "KDW/RM" => { "prev" => nil, "next" => nil, "title" => "Related Material", "level" => "series" }}

    @ead_collection.governed_items.length.should == expected_nodes.length

    @ead_collection.governed_items.each do |curr_child|
        expected_nodes.has_key?(curr_child.unitid).should == true

        if (curr_child.previous_sibling == nil)
          expected_nodes[curr_child.unitid]["prev"].should == nil
        else
          expected_nodes[curr_child.unitid]["prev"].should == curr_child.previous_sibling.pid
        end

        if (curr_child.next_sibling == nil)
          expected_nodes[curr_child.unitid]["next"].should == nil
        else
          expected_nodes[curr_child.unitid]["next"].should == curr_child.next_sibling.pid
        end

        curr_child.title.should == [ expected_nodes[curr_child.unitid]["title"]]
        curr_child.ead_level.should == expected_nodes[curr_child.unitid]["level"]
    end
  end

  xit "should add new children if the batch is a EncodedArchivalDescriptionComponent" do
    @ead_collection.save
    @ead_collection.synchronize_children_to_metadata
    ead_series = Batch.find(@ead_collection.governed_items[0].pid)
    ead_series.synchronize_children_to_metadata

    expected_nodes = { "KDW/RM/02" => { "prev" => nil, "next" => nil, "title" => "Ephemera", "level" => "file" }}

    ead_series.governed_items.length.should == expected_nodes.length

    ead_series.governed_items.each do |curr_child|
        expected_nodes.has_key?(curr_child.unitid).should == true

        if (curr_child.previous_sibling == nil)
          expected_nodes[curr_child.unitid]["prev"].should == nil
        else
          expected_nodes[curr_child.unitid]["prev"].should == curr_child.previous_sibling.pid
        end

        if (curr_child.next_sibling == nil)
          expected_nodes[curr_child.unitid]["next"].should == nil
        else
          expected_nodes[curr_child.unitid]["next"].should == curr_child.next_sibling.pid
        end

        curr_child.title.should == [ expected_nodes[curr_child.unitid]["title"]]
        curr_child.ead_level.should == expected_nodes[curr_child.unitid]["level"]
    end
  end

  xit "should not modify a child's metadata if the updated child's metadata is identical to it's previous version" do
    # compare the datestamps of children that should not change
    @ead_collection.save
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
  end

  after(:each) do
    unless @ead_collection.new_record?
      # Delete all descendants of @ead_collection and their generic files
      Batch.find(ActiveFedora::SolrService.solr_name('ancestor_id', :stored_searchable) => @ead_collection.pid).each do |obj|
        obj.generic_files.each do |file_obj|
          file_obj.delete
        end
        obj.delete
      end
      @ead_collection = Batch.find(@ead_collection.pid) #hmmm, have to do this before I delete otherwise I get a 404 error!
      @ead_collection.delete
    end
  end

end
