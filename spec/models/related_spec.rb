describe 'Related' do
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

    it 'should accept related objects' do
      rels = DRI::Related.new
      rels.related = [@a, @b]
      rels.save
      expect(rels).to be_valid
    end

    it 'should allow assignment to objects' do
      rels = DRI::Related.new
      rels.related = [@a, @b]
      rels.save

      @a.relations = [rels]
      @a.save

      @a.reload
      expect(@a.relations).to eq [rels]
    end

    it 'should return related' do
      rels = DRI::Related.new
      rels.related = [@a, @b]
      rels.save

      @a.relations = [rels]
      @a.save

      @a.reload
      expect(@a.relations.first.related).to match_array([@a, @b])
    end
  end
end
