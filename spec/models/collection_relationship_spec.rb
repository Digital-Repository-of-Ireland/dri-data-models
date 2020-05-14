describe 'CollectionRelationship' do
  context 'object methods' do
    before(:each) do
     @dc = fixture('audios/dublin_core_audio_sample1.xml')
     @ds = DRI::Metadata::QualifiedDublinCore.from_xml(@dc)
     @a = DRI::QualifiedDublinCore.new
     @a.update_metadata(@ds.to_xml)
     @a.title = "Object A"
     @a.save

     @b = DRI::QualifiedDublinCore.new
     @b.update_metadata(@ds.to_xml)
     @b.title = "Object B"
     @b.save
    end

    after(:each) do
      @a.delete
      @b.delete
    end

    it 'should allow collection to be related to another collection' do
      rel = @a.collection_relationships.build(collection_relative_id: @b.id)
      rel.save

      @a.reload
      expect(@a.collection_relatives).to eq [@b]
    end

    it 'should be possible to find collections that have been related to this collection' do
      rel = @b.collection_relationships.build(collection_relative_id: @a.id)
      rel.save

      @a.reload
      expect(@a.inverse_collection_relatives).to eq [@b]
    end

    it 'should index the relationship' do
      rel = @a.collection_relationships.build(collection_relative_id: @b.id)
      rel.save

      @a.reload
      expect(@a.to_solr['isMemberOf_ssim']).to eq [@b.noid]
    end

  end
end
