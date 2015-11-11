describe 'Mods' do
  context 'create new mods xml' do
    before(:each) do
      @md_collection = DRI::Metadata::Mods.new
    end

    it 'should have an xml_template method returning desired xml' do
      namespaces = { 'xmlns:xlink' => 'http://www.w3.org/1999/xlink',
                     'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                     'xmlns:mods' => 'http://www.loc.gov/mods/v3',
                     'xmlns:marcrel' => 'http://www.loc.gov/marc.relators/',
                     'xmlns:dcterms' => 'http://purl.org/dc/terms/',
                     'xmlns:copyrightMD' => 'http://www.cdlib.org/inside/diglib/copyrightMD' }
      # collection
      empty_xml = @md_collection.class.xml_template
      empty_xml.should be_a_kind_of(Nokogiri::XML::Document)
      # namespaces
      empty_xml.namespaces.should === namespaces
      empty_xml.root.name.should eq('mods')
    end
  end

  context 'modify existing mods xml' do
    before(:each) do
      @md_collection = DRI::Metadata::Mods.new
      @mods_ns = { 'xml:mods' => 'http://www.loc.gov/mods/v3' }

      @subjects_hash = [{ values: [{ tag: 'topic', content: 'Stained glass' },
                                   { tag: 'temporal', start: '18900101', end: '19721231', encoding: 'w3cdtf' },
                                   { tag: 'temporal', start: '20150101', end: '', encoding: 'iso8601' }], authority: 'lcsh' },
                        { values: [{ tag: 'topic', content: 'Correspondence' },
                                   { tag: 'name', display: 'St. Agnes of Montepulciano', role: 'pat' },
                                   { tag: 'geographic', content: 'Killeshandra', uri: 'http://data.logainm.ie/place/5104' }], authority: 'local' }]
    end

    it 'should update creator nodes' do
      c_hash = { display: ['A. Nolan'], authority: ['marcrelator'], role: ['cre'] }
      # Collection
      # Remove name tag for creators
      @md_collection.ng_xml.search('//mods:name', @mods_ns).each(&:remove)
      @md_collection.add_creator(c_hash)
      creators = @md_collection.ng_xml.search('//mods:name', @mods_ns)
      expect(creators.size).to eq 1

      c_hash = { display: ['B. Whitehall'], authority: ['marcrelator'], role: ['art'] }
      # Collection
      @md_collection.add_creator(c_hash)
      creators = @md_collection.ng_xml.search('//mods:name', @mods_ns)
      expect(creators.size).to eq 1
      expect(creators.first.at('./mods:namePart', @mods_ns).content).to eq('B. Whitehall')
      expect(creators.first.at('./mods:role/mods:roleTerm[@type="code"]', @mods_ns).content).to eq('art')
    end

    it 'should update contributor nodes' do
      c_hash = { display: ['A. Nolan'], authority: ['marcrelator'], role: ['ctb'] }
      # Collection
      # Remove name tag for creators
      @md_collection.ng_xml.search('//mods:name', @mods_ns).each(&:remove)
      @md_collection.add_contributor(c_hash)
      ctbs = @md_collection.ng_xml.search('//mods:name', @mods_ns)
      expect(ctbs.size).to eq 1

      c_hash = { display: ['B. Whitehall'], authority: ['marcrelator'], role: ['rcp'] }
      # Collection
      @md_collection.add_contributor(c_hash)
      ctbs = @md_collection.ng_xml.search('//mods:name', @mods_ns)
      expect(ctbs.size).to eq 1
      expect(ctbs.first.at('./mods:namePart', @mods_ns).content).to eq('B. Whitehall')
      expect(ctbs.first.at('./mods:role/mods:roleTerm[@type="code"]', @mods_ns).content).to eq('rcp')
    end

    it 'should update name_coverage nodes' do
      n_hash = [{ values: [{ tag: 'name', display: 'St. Agnes of Montepulciano', role: 'pat' }], authority: 'lcsh' }]

      @md_collection.ng_xml.search('//mods:subject').each(&:remove)
      @md_collection.add_subject(n_hash)
      names = @md_collection.ng_xml.search('//mods:subject', @mods_ns)
      expect(names.size).to eq 1

      n_hash = [{ values: [{ tag: 'name', display: 'St. Mary of Christ', role: 'rcp' }], authority: 'local' }]

      @md_collection.add_subject(n_hash)
      names = @md_collection.ng_xml.search('//mods:subject', @mods_ns)
      expect(names.size).to eq 1

      expect(names.first.at('./@authority').content).to eq('local')
      expect(names.first.at('./mods:name/mods:namePart').content).to eq('St. Mary of Christ')
      expect(names.first.at('./mods:name/mods:role/mods:roleTerm[@type="code"]').content).to eq('rcp')
    end

    it 'should update temporal_coverage nodes' do
      d_hash = [{ values: [{ tag: 'temporal', start: '18900101', end: '19721231', encoding: 'w3cdtf' }], authority: 'lcsh' }]

      @md_collection.ng_xml.search('//mods:subject').each(&:remove)

      @md_collection.add_subject(d_hash)
      dates = @md_collection.ng_xml.search('//mods:subject', @mods_ns)
      expect(dates.size).to eq 1
      expect(dates.first.at('./mods:temporal[@point="start"]', @mods_ns).content).to eq('18900101')
      expect(dates.first.at('./mods:temporal[@point="end"]', @mods_ns).content).to eq('19721231')
    end

    it 'should update geographical coverage nodes' do
      geog_hash = [{ values: [{ tag: 'geographic',
                                content: 'Killeshandra',
                                uri: 'http://data.logainm.ie/place/5104' }],
                     authority: 'local' }]

      @md_collection.ng_xml.search('//mods:subject', @mods_ns).each(&:remove)
      @md_collection.add_subject(geog_hash)
      geogs = @md_collection.ng_xml.search('//mods:subject', @mods_ns)
      expect(geogs.size).to eq 1

      geog_hash = [{ values: [{ tag: 'geographic',
                                content: 'Dublin',
                                uri: 'http://data.logainm.ie/place/200' }],
                     authority: 'geo' }]

      @md_collection.add_subject(geog_hash)
      geogs = @md_collection.ng_xml.search('//mods:subject', @mods_ns)
      expect(geogs.size).to eq 1

      expect(geogs.first.at('./@authority').content).to eq('geo')
      expect(geogs.first.at('./mods:geographic/@valueURI').content).to eq('http://data.logainm.ie/place/200')
      expect(geogs.first.at('./mods:geographic').content).to eq('Dublin')
    end
  end

  context 'validation of DRI compulsory elements' do
    before(:each) do
      @collection_xml = fixture('mods/ns/mods-collection.xml')
      @mods_col = DRI::Mods.new
      @ds = DRI::Metadata::Mods.from_xml(@collection_xml)
      @mods_col.update_metadata(@ds.to_xml)

      @attributes_hash = { title: ['Clarke Studios: Photographs'],
                           creator: ['Test Creator'],
                           contributor: ['Test contributor'],
                           desc_abstract: ['Clarke Studios: Photographs is a subsection of the Clarke Stained Glass Studios Collection, and contains photographs of designs, stained glass windows and Clarke Studios staff'],
                           desc_phys_desc: ['Test physical description'],
                           desc_note: ['Test note'],
                           desc_toc: ['Test table of contents'],
                           desc_physdesc_note: ['Note under physical description'],
                           rights: ['Copyright 2015 The Board of Trinity College Dublin. Images are available for single-use academic application only. Publication, transmission or display is prohibited without formal written approval of Trinity College Library, Dublin.'],
                           origin_metadata: [[{ tag: 'dateCreated', start: '18930101', end: '19721231', encoding: 'iso8601' },
                                              { tag: 'dateIssued', start: '1972', end: '', encoding: 'iso8601' }],
                                             [{ tag: 'publisher', content: 'Publisher name 1' }]],
                           type: { content: ['collections (object groupings)', 'Photographs'], collection: true },
                           language: { code: ['eng'], text: ['English'],
                                       type: ['mixed material'] }
      }
    end

    after(:each) do
      @mods_col.delete unless @mods_col.new_record?
    end

    it 'should validate the presence of the title metadata field' do
      @mods_col.should be_valid
      @mods_col.title = ['']
      @mods_col.should_not be_valid
    end

    it 'should validate the presence of creator field' do
      @mods_col.should be_valid
      @mods_col.creator = []
      @mods_col.contributor = []
      @mods_col.should_not be_valid
    end

    it 'should validate creator presence if any role name present' do
      @mods_col.creator = []
      @mods_col.should be_valid
      expect(@mods_col.creator.empty?).to eq true
    end

    it 'should validate the presence of the description metadata fields' do
      @mods_col.should be_valid
      @mods_col.desc_abstract = []
      @mods_col.should_not be_valid
      @mods_col.desc_note = ['This is a note description']
      @mods_col.should be_valid
    end

    it 'should validate the presence of the type attribute' do
      # <typeOfResource collection="yes" />
      @mods_col.should be_valid
      @mods_col.mods_type_collection = nil
      @mods_col.mods_genre = { content: [''], authority: [''] }
      @mods_col.should_not be_valid
      @mods_col.type = { content: ['text'], collection: false }
      @mods_col.should be_valid
    end

    it 'should validate the presence of mods_genre if type not present' do
      @mods_col.should be_valid
      @mods_col.mods_type_collection = nil
      @mods_col.mods_genre = { content: [''], authority: [''] }
      @mods_col.should_not be_valid
      @mods_col.mods_genre = { content: ['Manuscript'], authority: ['aat'] }
      @mods_col.should be_valid
    end

    it 'should validate the presence of term identifier with attr type=local' do
      @mods_col.should be_valid
      @mods_col.mods_id_local = ''
      @mods_col.should_not be_valid
    end

    it 'should validate the presence of creation date' do
      @mods_col.should be_valid
      @mods_col.origin_metadata = [{ '0' => { tag: 'dateCreated', start: '', end: '', encoding: '' } }]
      @mods_col.should_not be_valid
    end

    it 'should validate creation date if any date present' do
      @mods_col.should be_valid
      @mods_col.origin_metadata = [{ '0' => { tag: 'dateCreated', start: '', end: '', encoding: '' },
                                   '1' => { tag: 'dateIssued', start: '2005', end: '2006', encoding: '' } }]
      @mods_col.should be_valid
    end

    it 'should validate the presence of the rights attribute' do
      @mods_col.should be_valid
      @mods_col.rights = []
      @mods_col.should_not be_valid
      @mods_col.rights = { status: ['copyrighted'], rights: ['All rigths reserved'], note: [''] }
      @mods_col.should be_valid
    end
  end

  context 'terminology mappings' do
    before(:each) do
      @collection_xml = fixture('mods/ns/mods-collection.xml')
      @mods_col = DRI::Mods.new
      @ds = DRI::Metadata::Mods.from_xml(@collection_xml)
      @mods_col.update_metadata(@ds.to_xml)

      @mods_record = DRI::Mods.new
      @mods_record.mods_id_local = 'MODS-ID-9876'

      @subjects_hash = [{ values: [{ tag: 'topic', content: 'Stained glass' },
                                   { tag: 'temporal', start: '18900101', end: '19721231', encoding: 'w3cdtf' },
                                   { tag: 'temporal', start: '20150101', end: '', encoding: 'iso8601' }], authority: 'lcsh' },
                        { values: [{ tag: 'topic', content: 'Correspondence' },
                                   { tag: 'name', display: 'St. Agnes of Montepulciano', role: 'pat', authority: '' }], authority: 'local' }]

      @attributes_hash = { title: ['Clarke Studios: Photographs'],
                           creator: { display: ['Test creator'], role: ['aut'], authority: ['lhsc']},
                           contributor: { display: ['Test contributor'], role: ['ctb'], authority: ['']},
                           desc_abstract: ['Clarke Studios: Photographs is a subsection of the Clarke Stained Glass Studios Collection, and contains photographs of designs, stained glass windows and Clarke Studios staff'],
                           desc_phys_desc: ['Test physical description'],
                           desc_note: ['Test note'],
                           desc_toc: ['Test table of contents'],
                           desc_physdesc_note: ['Note under physical description'],
                           rights: ['Copyright 2015 The Board of Trinity College Dublin. Images are available for single-use academic application only. Publication, transmission or display is prohibited without formal written approval of Trinity College Library, Dublin.'],
                           origin_metadata: [{ '0' => { tag: 'dateCreated', start: '18930101', end: '19721231', encoding: 'iso8601' },
                                               '1' => { tag: 'dateIssued', start: '1972', end: '', encoding: 'iso8601' } },
                                             { '0' => { tag: 'publisher', content: 'Publisher name 1' } }],
                           subject: @subjects_hash,
                           type: { content: ['collections (object groupings)', 'Photographs'], collection: true, authority: ['aat', 'gmgpc'] },
                           language: { code: ['eng'], text: ['English'],
                           type: ['mixed material'] }
      }
    end

    after(:each) do
      @mods_col.delete unless @mods_col.new_record?
      @mods_record.delete unless @mods_record.new_record?
    end

    it "should expose the collection\'s identifiers" do
      expect(@mods_col.mods_id_local).to eq 'MODS-ID-1234' # :multiple => false
      expect(@mods_col.identifier).to match_array(%w(MODS-ID-1234
                                                     http://example.org/collection/2#
                                                     MS11182-030_1))
      expect(@mods_col.identifier_doi).to match_array(['MS11182-030_1'])
      expect(@mods_col.identifier_uri).to match_array(['http://example.org/collection/2#'])
    end

    it 'should use the type attr to determine whether is a collection' do
      @mods_col.save
      expect(@mods_col.is_collection?).to eq true
      expect(@mods_col.is_root_collection?).to eq true

      expect(@mods_record.is_collection?).to eq false
    end

    it 'indexes valid temporal metadata' do
      indexed_md = @mods_col.descMetadata.to_solr
      temporal = ['name=Jan 01, 1980 - Jan 01, 1990; start=1980; end=1990;']
      expect(indexed_md['temporal_coverage_tesim']).to match_array(temporal)
      cdate = ['name=Jan 01, 1889; start=1889;']
      expect(indexed_md['creation_date_tesim']).to match_array(cdate)
      pdate = ['name=Beginning of 2000;']
      expect(indexed_md['published_date_tesim']).to match_array(pdate)
      expect(indexed_md['cdateRange']).to match_array(['1889 1889'])
      expect(indexed_md['sdateRange']).to match_array(['1980 1990'])
      expect(indexed_md['pdateRange']).to be_nil
    end

    it 'indexes valid geospatial information' do
      @mods_col.subject_metadata = [{ values: [{ tag: 'geographic', content: 'Baile Chairdif', uri: 'http://data.logainm.ie/place/25881' }], authority: 'local' }]

      expect(@mods_col.geocode_logainm).to match_array(['http://data.logainm.ie/place/25881'])
      expect(@mods_col.geographical_coverage).to match_array(['Baile Chairdif', 'http://data.logainm.ie/place/25881'])
    end
  end
end
