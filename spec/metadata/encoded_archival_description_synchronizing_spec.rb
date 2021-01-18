
describe 'EncodedArchivalDescription' do

  before(:each) do
    allow(DRI.queue).to receive(:push)
    allow_any_instance_of(DRI::ModelSupport::EadSupport).to receive(:preserve)

    @collection_xml = fixture("ead/collections/ead_collection_dtd.xml")
    @collection_modified_xml = fixture("ead/collections/ead_collection_modified_dtd.xml")
    @ead_collection = DRI::EadCollection.new
    @ead_collection.update_metadata(DRI::Metadata::EncodedArchivalDescription.from_xml(@collection_xml).to_xml, true)
    @ead_collection.ingest_files_from_metadata = 'false'
    @ead_collection.save
  end

  it "should add new children if it's metadata specifies this" do
    #@ead_collection.save
    @ead_collection.synchronize_children_to_metadata

    expected_nodes = { "KDW/RM" => { "prev" => nil, "next" => nil, "title" => "Related Material", "level" => "series" }}

    @ead_collection.governed_items.size.should == expected_nodes.length

    @ead_collection.governed_items.each do |curr_child|
        expected_nodes.has_key?(curr_child.identifier.first).should == true

        if (curr_child.previous_sibling.blank?)
          expected_nodes[curr_child.identifier.first]["prev"].should == nil
        else
          expected_nodes[curr_child.identifier.first]["prev"].should == curr_child.previous_sibling.id
        end

        if (curr_child.next_sibling.blank?)
          expected_nodes[curr_child.identifier.first]["next"].should == nil
        else
          expected_nodes[curr_child.identifier.first]["next"].should == curr_child.next_sibling.first.id
        end

        curr_child.title.should == [expected_nodes[curr_child.identifier.first]["title"]]
        curr_child.ead_level.should == expected_nodes[curr_child.identifier.first]["level"]
    end
  end

  it "should add new children if the object is a EncodedArchivalDescriptionComponent" do
    # @ead_collection.save
    @ead_collection.synchronize_children_to_metadata
    ead_series = DRI::EadComponent.find_by_alternate_id(@ead_collection.governed_items[0].alternate_id)
    ead_series.synchronize_children_to_metadata

    expected_nodes = { "KDW/RM/02" => { "prev" => nil, "next" => nil, "title" => "Ephemera", "level" => "file" }}

    ead_series.governed_items.size.should == expected_nodes.length

    ead_series.governed_items.each do |curr_child|
        expected_nodes.has_key?(curr_child.identifier.first).should == true

        if (curr_child.previous_sibling.blank?)
          expected_nodes[curr_child.identifier.first]["prev"].should == nil
        else
          expected_nodes[curr_child.identifier.first]["prev"].should == curr_child.previous_sibling.id
        end

        if (curr_child.next_sibling.blank?)
          expected_nodes[curr_child.identifier.first]["next"].should == nil
        else
          expected_nodes[curr_child.identifier.first]["next"].should == curr_child.next_sibling.id
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
    new_collection = DRI::EadCollection.find_or_create(@ead_collection.alternate_id)
    new_collection.update_metadata(DRI::Metadata::EncodedArchivalDescription.from_xml(@collection_modified_xml).to_xml, false)
    new_collection.save

    title = "Fake Invitation"
    solr_query = "title_tesim:\"#{title.to_s}\""
    new_obj = Valkyrie::MetadataAdapter.find(:index_solr).persister.connection.get('select', params: { q: solr_query, defType: "edismax", qf: "alternate_identifier,title" })['response']['docs']
    new_obj.length.should == 1
  end

  after(:each) do
    unless @ead_collection.new_record?
      @ead_collection = DRI::EadCollection.find_by_alternate_id(@ead_collection.alternate_id) #hmmm, have to do this before I delete otherwise I get a 404 error!
      @ead_collection.delete
    end
  end

end
