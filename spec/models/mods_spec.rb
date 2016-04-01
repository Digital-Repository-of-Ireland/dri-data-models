describe 'Mods' do
  context 'object methods' do
    # Before each test create test objects
    before(:each) do
      @mods_xml = fixture('mods/ns/sample-mods.xml')
      @mods_record = DRI::Mods.new
      @ds = DRI::Metadata::Mods.from_xml(@mods_xml)
      @mods_record.update_metadata(@ds.ng_xml)

      @mods_wrapper_xml = fixture('mods/ns/modscollection-container.xml')

      @mods_wrapper = DRI::Mods.new
      @ds_w = DRI::Metadata::Mods.from_xml(@mods_wrapper_xml)
      @mods_wrapper.update_metadata(@ds_w.to_xml)
    end

    # After each test clean-up
    after(:each) do
      @mods_record.delete unless @mods_record.new_record?

      unless @mods_wrapper.new_record?
        @mods_wrapper.governed_items.each { |o| o.delete }
        @mods_wrapper.delete
      end
    end

    it 'should find an existing object from fedora' do
      @mods_record.save
      @collection = DRI::Mods.find_or_create(@mods_record.id)
      expect(@collection.new_record?).to eq false
    end

    it 'should create a new object if there isnt an existing object for a given id' do
      @mods_record.save
      @collection = DRI::Mods.find_or_create('fake-mods-id')
      expect(@collection.new_record?).to eq true
      @collection.delete
    end

    it 'should be a kind of Batch and Mods' do
      @mods_record.should be_kind_of(DRI::Batch)
      @mods_record.should be_kind_of(DRI::Mods)
    end

    it 'should have the specified datastreams' do
      @mods_record.attached_files.keys.should include(:descMetadata)
      @mods_record.descMetadata.should be_kind_of(DRI::Metadata::Mods)
      @mods_record.attached_files.keys.should include(:fullMetadata)
      @mods_record.fullMetadata.should be_kind_of(DRI::Metadata::FullMetadata)
      @mods_record.attached_files.keys.should include(:properties)
      @mods_record.properties.should be_kind_of(DRI::Metadata::Properties)
    end

    it 'should have mods namespace prefix' do
      mods_ns = { 'xmlns:mods' => 'http://www.loc.gov/mods/v3' }
      expect(@mods_record.descMetadata.ng_xml.namespaces).to include(mods_ns)
    end

    it 'should add create mods records if modsCollection is used in metadata' do
      @mods_wrapper.save
      @mods_wrapper.create_mods_records

      @mods_wrapper.reload

      expect(@mods_wrapper.governed_items.any?).to eq true
      expect(@mods_wrapper.governed_items.count).to eq 2
    end
  end

  context 'update attributes methods' do
    # Before each test create test objects
    before(:each) do
      @mods_xml = fixture('mods/ns/sample-mods.xml')

      @mods_record = DRI::Mods.new
      @ds = DRI::Metadata::Mods.from_xml(@mods_xml)
      @mods_record.update_metadata(@ds.to_xml)

      @mods_record_att = DRI::Mods.new
      @mods_record_att.mods_id_local = 'mods-col-234589'

      @subjects_hash = [{ values: [{ tag: 'topic', content: 'Stained glass' },
                                   { tag: 'temporal', start: '18900101', end: '19721231', encoding: 'w3cdtf' },
                                   { tag: 'temporal', start: '20150101', end: '', encoding: 'iso8601' }], authority: 'lcsh' },
                        { values: [{ tag: 'topic', content: 'Correspondence' },
                                   { tag: 'name', display: 'St. Agnes of Montepulciano', role: 'pat' },
                                   { tag: 'geographic', content: 'Killeshandra', uri: 'http://data.logainm.ie/place/5104' }], authority: 'local' }]

      @attributes_hash = { title: ['Clarke Studios: Photographs'],
                           desc_abstract: ['Clarke Studios: Photographs is a subsection of the Clarke Stained Glass Studios Collection, and contains photographs of designs, stained glass windows and Clarke Studios staff'],
                           desc_note: ['Test note'],
                           desc_toc: ['Test table of contents'],
                           desc_physdesc_note: ['Note under physical description'],
                           rights: ['Copyright 2015 The Board of Trinity College Dublin. Images are available for single-use academic application only. Publication, transmission or display is prohibited without formal written approval of Trinity College Library, Dublin.'],
                           origin_metadata: [{ '0' => { tag: 'dateCreated', start: '18930101', end: '19721231', encoding: 'iso8601' },
                                               '1' => { tag: 'dateIssued', start: '1972', end: '', encoding: 'iso8601' } },
                                             { '0' => { tag: 'publisher', content: 'Publisher name 1' } }],
                           subject_metadata: @subjects_hash,
                           type: { collection: true, content: ['mixed material']},
                           mods_genre: { authority: ['aat', ''], content: ['collections (object groupings)', 'Photographs'] },
                           language: ['English'],
                           roles: { 'name' => ['Test host', 'new producer'],
                                    'type' => ['role_hst', 'role_pro'],
                                    'authority' => ['lhsc', ''] }
      }
    end

    # After each test clean-up
    after(:each) do
      @mods_record.delete unless @mods_record.new_record?
      @mods_record_att.delete unless @mods_record_att.new_record?
    end

    it 'creates an object with DRI fields using accessors' do
      obj = DRI::Mods.new
      obj.mods_id_local = 'mods-01234-col'
      obj.title = ['Test title']
      obj.mods_type_collection = 'mixed material'
      obj.creator = ['Tes creator']
      obj.contributor = ['Tes contributor']
      obj.rights = ['All rights reserved']
      obj.creation_date_start = ['2015']
      obj.creation_date_end = ['2016']
      obj.desc_abstract = ['Test abstract for the collection']

      obj.should be_valid
    end

    it 'should update the object\'s attributes' do
      @mods_record_att = DRI::Mods.new
      @mods_record_att.attributes = @attributes_hash
      att_hash = @mods_record_att.retrieve_hash_attributes
      att_hash.should === @attributes_hash
    end

    it 'should update the role attributes' do
      new_roles = {
          'authority' => ['', ''],
          'type' => ['role_hst', 'role_pro'],
          'name' => ['new host', 'new producer']}

      # Via attributes update
      @mods_record_att.attributes = @attributes_hash
      @mods_record_att.role_pro.should == ['new producer']
      @mods_record_att.creator.should == ['']

      # via role= method
      @mods_record_att = DRI::Mods.new
      @mods_record_att.roles = new_roles
      @mods_record_att.role_pro.should == ['new producer']
      @mods_record_att.role_hst.should == ['new host']
    end
  end

  context 'Relationships' do
    # Before each test create test objects
    before(:each) do
      @mods_wrapper_xml = fixture('mods/ns/modscollection-container.xml')
      @mods_record_xml = fixture('mods/ns/sample-mods.xml')
      @mods_subcol_xml = fixture('mods/ns/mods-subcollection.xml')

      @mods_wrapper = DRI::Mods.new
      @ds_w = DRI::Metadata::Mods.from_xml(@mods_wrapper_xml)
      @mods_wrapper.update_metadata(@ds_w.to_xml)
      @mods_wrapper.save

      @mods_record = DRI::Mods.new
      @ds = DRI::Metadata::Mods.from_xml(@mods_record_xml)
      @mods_record.update_metadata(@ds.to_xml)
      @mods_record.governing_collection = @mods_wrapper
      @mods_record.save

      @mods_subcol = DRI::Mods.new
      @ds_s = DRI::Metadata::Mods.from_xml(@mods_subcol_xml)
      @mods_subcol.update_metadata(@ds_s.to_xml)
      @mods_subcol.governing_collection = @mods_wrapper
      @mods_subcol.save
    end

    it 'should add relationship host and referenced_by' do
      md_relationships_hash = @mods_record.get_relationships_records

      added_rels = [DRI::Mods.find(md_relationships_hash[:referenced_by].first).mods_id_local,
                    DRI::Mods.find(md_relationships_hash[:host].first).mods_id_local]

      expect(added_rels).to  match(%w(http://example.org/subcollection/1# MODS-ID-1234))
    end

    after(:each) do
      unless @mods_wrapper.new_record?
        @mods_wrapper.governed_items.each { |o| o.delete }
        @mods_wrapper.delete
      end
    end
  end
end
