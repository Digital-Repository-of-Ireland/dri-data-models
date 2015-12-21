describe 'QualifiedDublinCore' do
  context 'object methods' do
    before(:each) do
      # This gives you a test article object that can be used in any of the tests
      @audio = DRI::QualifiedDublinCore.new
      @audio.type = ['Sound']

      @attributes_hash = {
        'creator' => ['New creator'],
        'title' => ['The Audio Title'],
        'rights' => ['This is a statement about the rights associated with this object'],
        'role_hst' => ['Collins, Michael'],
        'role_pro' => ['Collins, Michael'],
        'role_aut' => ['Valera, Eamon, de', 'Connolly, James'],
        'language' => ['ga'],
        'description' => ['Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'],
        'published_date' => ['1916-04-01'],
        'creation_date' => ['1916-01-01'],
        'source' => ['CD nnn nuig'],
        'geographical_coverage' => ['Dublin'],
        'temporal_coverage' => ['1900s'],
        'subject' => ['Ireland','something else']
      }
    end

    after(:each) do
      unless @audio.new_record?
        @audio.delete
      end
    end

    it 'returns correct count for has_many associations if new object' do
      # Issue 1320
      expect(@audio.generic_files.any?).to eq false
      expect(@audio.documentation_objects.any?).to eq false
      expect(@audio.governed_items.any?).to eq false
    end

    it 'should be a collection if metadata specifies this' do
      @audio.type = ['Collection']

      expect(@audio.collection?).to eq true
    end

    it 'should assert content model' do
      expect_any_instance_of(DRI::Batch).to receive(:assert_content_model)
      @dc = DRI::Batch.with_standard(:qdc)
    end

    it 'should have asserted the content model' do
      expect(@audio.has_model.to_a).to match_array(['DRI::QualifiedDublinCore', 'DRI::Batch'])
    end

    it 'should load from xml' do
      @dc = fixture('audios/dublin_core_audio_sample1.xml')
      @ds = DRI::Metadata::QualifiedDublinCore.from_xml(@dc)
      audio2 = DRI::QualifiedDublinCore.new
      audio2.update_metadata(@ds.to_xml)
      audio2.descMetadata.content_changed?.should == true
      audio2.should be_valid
      audio2.creator.should == ['Gallagher, Damien']
    end

    it 'should retrieve an existing object from fedora' do
      @audio.update_attributes(@attributes_hash)
      @audio.save
      @audio.new_record?.should == false
      @audio3 = DRI::QualifiedDublinCore.find_or_create(@audio.id)
      @audio3.title.should == @attributes_hash['title']
      @audio3.rights.should == @attributes_hash['rights']
      @audio3.description.should == @attributes_hash['description']
      @audio3.published_date.should == @attributes_hash['published_date']
      @audio3.creation_date.should == @attributes_hash['creation_date']
      @audio3.language.should == @attributes_hash['language']
      @audio3.role_pro.should == @attributes_hash['role_hst']
      @audio3.role_hst.should == @attributes_hash['role_pro']
      @audio3.role_aut.should == @attributes_hash['role_aut']
      @audio3.subject.should == @attributes_hash['subject']
      @audio3.source.should == @attributes_hash['source']
      @audio3.geographical_coverage.should == @attributes_hash['geographical_coverage']
      @audio3.temporal_coverage.should == @attributes_hash['temporal_coverage']
      @audio3.should be_valid
    end

    it 'should have the specified datastreams' do
      # Check for descMetadata datastream with MODS in it
      @audio.attached_files.keys.should include(:descMetadata)
      @audio.descMetadata.should be_kind_of DRI::Metadata::QualifiedDublinCore
      # Check for properties datastream
      @audio.attached_files.keys.should include(:properties)
      @audio.properties.should be_kind_of DRI::Metadata::Properties
    end

    it 'should not be valid with no metadata' do
      @audio.should_not be_valid
    end

    it 'should create a valid audio object when valid metadata is ingested' do
      # From ingestion
      @dc = fixture('audios/dublin_core_audio_sample1.xml')
      @ds = DRI::Metadata::QualifiedDublinCore.from_xml(@dc)
      @audio2 = DRI::QualifiedDublinCore.new
      @audio2.update_metadata(@ds.to_xml)
      @audio2.should be_valid
    end

    it 'the status property should be set as "draft" when a new Audio object is created' do
      @audio = DRI::QualifiedDublinCore.new
      @audio.status.should == 'draft'
    end

    #it 'should have the attributes of a audio and support update_attributes' do
    #  @audio.update_attributes( @attributes_hash )
    #
    #  # These attributes have not been marked 'unique' in the call to the delegate, which causes the results to be arrays
    #  @audio.title.class.to_s.should == 'Array'
    #  @audio.rights.class.to_s.should == 'Array'
    #  @audio.description.class.to_s.should == 'Array'
    #  @audio.language.class.to_s.should == 'Array'
    #  @audio.creation_date.class.to_s.should == 'Array'
    #  @audio.role_hst.class.to_s.should == 'Array'
    #  @audio.role_pro.class.to_s.should == 'Array'
    #  @audio.role_aut.class.to_s.should == 'Array'
    #  @audio.subject.class.to_s.should == 'Array'
    #  @audio.source.class.to_s.should == 'Array'
    #  @audio.geographical_coverage.class.to_s.should == 'Array'
    #  @audio.temporal_coverage.class.to_s.should == 'Array'
    #  @audio.published_date.class.to_s.should == 'Array'

      # The value should match what was set in the attributes_hash above
    #  @audio.title.should == @attributes_hash['title']
    #  @audio.rights.should == @attributes_hash['rights']
    #  @audio.description.should == @attributes_hash['description']
    #  @audio.published_date.should == @attributes_hash['published_date']
    #  @audio.creation_date.should == @attributes_hash['creation_date']
    #  @audio.language.should == @attributes_hash['language']
    #  @audio.role_pro.should == @attributes_hash['role_hst']
    #  @audio.role_hst.should == @attributes_hash['role_pro']
    #  @audio.role_aut.should == @attributes_hash['role_aut']
    #  @audio.subject.should == @attributes_hash['subject']
    #  @audio.source.should == @attributes_hash['source']
    #  @audio.geographical_coverage.should == @attributes_hash['geographical_coverage']
    #  @audio.temporal_coverage.should == @attributes_hash['temporal_coverage']
    #
    #end

    it 'should update the role attributes' do
      new_roles = {
          'type' => ['role_hst', 'role_pro', 'role_aut'],
          'name' => ['new host', 'new producer', 'new author']}

      @audio.update_attributes(@attributes_hash)
      @audio.role_pro.should == @attributes_hash['role_hst']
      @audio.role_hst.should == @attributes_hash['role_pro']
      @audio.role_aut.should == @attributes_hash['role_aut']

      @audio.roles=(new_roles)
      @audio.role_pro.should == ['new producer']
      @audio.role_hst.should == ['new host']
      @audio.role_aut.should == ['new author']
    end

    it 'should validate the presence of the title metadata field' do
      # From ingestion
      @dc = fixture('audios/dublin_core_audio_notitle_sample.xml')
      @ds = DRI::Metadata::QualifiedDublinCore.from_xml(@dc)
      @audio2 = DRI::QualifiedDublinCore.new
      @audio2.update_metadata(@ds.to_xml)
      @audio2.should_not be_valid

      # From update_attributes assignment
      @audio = DRI::QualifiedDublinCore.new
      @attributes_hash[:title] = ['']
      @audio.update_attributes(@attributes_hash)
      @audio.should_not be_valid
      @audio = DRI::QualifiedDublinCore.new
      @attributes_hash.delete('title')
      @audio.update_attributes(@attributes_hash)
      @audio.should_not be_valid

      # From variable assignment
      @audio = DRI::QualifiedDublinCore.new
      @audio.description = ['blah']
      @audio.rights = ['blah']
      @audio.creator = ['blah']
      @audio.type = ['Sound']
      @audio.date = ['1916-04-01']
      @audio.title = []
      @audio.should_not be_valid

      @audio.title = ['']
      @audio.should_not be_valid
    end

    it 'should validate the presence of the creator metadata field' do
      # From ingestion
      @dc = fixture('audios/dublin_core_audio_nocreator_sample.xml')
      @ds = DRI::Metadata::QualifiedDublinCore.from_xml(@dc)
      @audio2 = DRI::QualifiedDublinCore.new
      @audio2.update_metadata(@ds.to_xml)
      @audio2.should be_valid
      @audio2.role_edt = []
      @audio2.role_aut = []
      @audio2.should_not be_valid
      expect(@audio2.descMetadata.custom_validations).to include(:creator)

      # From update_attributes assignment
      @audio = DRI::QualifiedDublinCore.new
      @attributes_hash[:creator] = ['']
      @attributes_hash[:role_hst] = ['']
      @attributes_hash[:role_pro] = ['']
      @attributes_hash[:role_aut] = ['']
      @audio.type = ['Sound']
      @audio.update_attributes(@attributes_hash)
      @audio.should_not be_valid
      expect(@audio.descMetadata.custom_validations).to include(:creator)

      # From variable assignment
      @audio = DRI::QualifiedDublinCore.new
      @audio.description = ['blah']
      @audio.rights = ['blah']
      @audio.creator = []
      @audio.type = ['Sound']
      @audio.date = ['1916-04-01']
      @audio.title = ['The title']
      @audio.should_not be_valid

      @audio.creator = ['']
      @audio.should_not be_valid
      expect(@audio.descMetadata.custom_validations).to include(:creator)
    end

    it 'should validate the presence of the description metadata field' do
      # From ingestion
      @dc = fixture('audios/dublin_core_audio_nodescription_sample.xml')
      @ds = DRI::Metadata::QualifiedDublinCore.from_xml(@dc)
      @audio.update_metadata @ds.to_xml
      @audio.should_not be_valid

      # From update_attributes assignment
      @audio = DRI::QualifiedDublinCore.new
      @attributes_hash[:description] = ['']
      @audio.update_attributes( @attributes_hash )
      @audio.should_not be_valid
      @audio = DRI::QualifiedDublinCore.new
      @attributes_hash.delete('description')
      @audio.update_attributes( @attributes_hash )
      @audio.should_not be_valid

      # From variable assignment
      @audio = DRI::QualifiedDublinCore.new
      @audio.title = ['blah']
      @audio.rights = ['blah']
      @audio.creator = ['blah']
      @audio.type = ['Sound']
      @audio.date = ['1916-04-01']
      @audio.description = []
      @audio.should_not be_valid

      @audio.description = ['']
      @audio.should_not be_valid

    end

    it 'should validate the presence of the rights metadata field' do
      # From ingestion
      @dc = fixture('audios/dublin_core_audio_norights_sample.xml')
      @ds = DRI::Metadata::QualifiedDublinCore.from_xml(@dc)
      @audio2 = DRI::QualifiedDublinCore.new
      @audio2.update_metadata @ds.to_xml
      @audio2.should_not be_valid

      # From update_attributes assignment
      @audio = DRI::QualifiedDublinCore.new
      @attributes_hash[:rights] = ['']
      @audio.update_attributes( @attributes_hash )
      @audio.should_not be_valid
      @audio = DRI::QualifiedDublinCore.new
      @attributes_hash.delete('rights')
      @audio.update_attributes( @attributes_hash )
      @audio.should_not be_valid

      # From variable assignment
      @audio = DRI::QualifiedDublinCore.new
      @audio.title = ['blah']
      @audio.rights = []
      @audio.creator = ['blah']
      @audio.type = ['Sound']
      @audio.description = ['blah']
      @audio.date = ['1916-04-01']
      @audio.should_not be_valid

      @audio.rights = ['']
      @audio.should_not be_valid
    end

    it 'should validate the presence of the type metadata field' do
      # From ingestion
      @dc = fixture('audios/dublin_core_audio_notype_sample.xml')
      @ds = DRI::Metadata::QualifiedDublinCore.from_xml(@dc)
      @audio2 = DRI::QualifiedDublinCore.new
      @audio2.update_metadata @ds.to_xml
      @audio2.should_not be_valid

      # From update_attributes assignment
      @audio = DRI::QualifiedDublinCore.new
      @attributes_hash[:type] = ['']
      @audio.update_attributes( @attributes_hash )
      @audio.should_not be_valid
      @audio = DRI::QualifiedDublinCore.new
      @attributes_hash.delete('type')
      @audio.update_attributes( @attributes_hash )
      @audio.should_not be_valid

      # From variable assignment
      @audio = DRI::QualifiedDublinCore.new
      @audio.title = ['blah']
      @audio.rights = ['blah']
      @audio.creator = ['blah']
      @audio.type = []
      @audio.date = ['1916-04-01']
      @audio.description = ['blah']
      @audio.should_not be_valid

      @audio.type = ['']
      @audio.should_not be_valid
    end

    it 'should validate the presence of the date metadata fields' do
      # From ingestion
      @dc = fixture('audios/dublin_core_audio_nodate_sample.xml')
      @ds = DRI::Metadata::QualifiedDublinCore.from_xml(@dc)
      @audio2 = DRI::QualifiedDublinCore.new
      @audio2.update_metadata @ds.to_xml
      @audio2.should_not be_valid

      # From update_attributes assignment
      @audio = DRI::QualifiedDublinCore.new
      @attributes_hash[:type] = ['']
      @audio.update_attributes( @attributes_hash )
      @audio.should_not be_valid
      @audio = DRI::QualifiedDublinCore.new
      @attributes_hash.delete('creation_date')
      @attributes_hash.delete('published_date')
      @audio.update_attributes( @attributes_hash )
      @audio.should_not be_valid

      # From variable assignment
      @audio = DRI::QualifiedDublinCore.new
      @audio.title = ['blah']
      @audio.rights = ['blah']
      @audio.creator = ['blah']
      @audio.date = []
      @audio.type = ['Sound']
      @audio.description = ['blah']
      @audio.should_not be_valid

      @audio.date = ['']
      @audio.should_not be_valid
    end
  end

  context 'indexing' do
    # Before each test create test objects
    before(:each) do
      @obj_xml = fixture('audios/dublin_core_audio_lang_sample.xml')
      @obj = DRI::QualifiedDublinCore.new
      @obj.update_metadata DRI::Metadata::Marc.from_xml(@obj_xml).to_xml
    end

    after(:each) do
      @obj.delete unless @obj.new_record?
    end

    it 'excludes DCMI Point, Box, Period metadata values from languages-based indices' do
      solr_doc = @obj.descMetadata.to_solr
      lang_keys = ['temporal_coverage_spa_tesim',
                   'temporal_coverage_tesim',
                   'geographical_coverage_gle_tesim',
                   'geographical_coverage_tesim']

      expect(solr_doc.keys).to include(*lang_keys)
      expect(solr_doc['temporal_coverage_spa_tesim']).to match(['Approx. Siglo XXI'])
      expect(solr_doc['temporal_coverage_tesim']).to match(['name=SAMPLE CENTURY; start=1900; end=1999;',
                                                            'name=Approx. Siglo XXI;'])
      expect(solr_doc['geographical_coverage_gle_tesim']).to match(['Co. na Gaillimhe'])
      expect(solr_doc['geographical_coverage_tesim']).to match(['Co. na Gaillimhe',
                                                                'name=Kilkenny; east=-7.2561; north=52.6477;'])
    end
  end

  context 'relationships' do
    # Before each test create test objects
    before(:each) do
      @col_xml = fixture('relationships/qdc/qdc-rel-col.xml')
      @obj_xml = fixture('relationships/qdc/qdc-rel-obj.xml')
      @col = DRI::QualifiedDublinCore.new
      @obj = DRI::QualifiedDublinCore.new
      @col.update_metadata DRI::Metadata::Marc.from_xml(@col_xml).to_xml
      @obj.update_metadata DRI::Metadata::Marc.from_xml(@obj_xml).to_xml

      @col.save
      @obj.governing_collection = @col
      @obj.save
    end

    after(:each) do
      unless @col.new_record?
        @col.governed_items.each { |o| o.delete }
        @col.delete
      end
    end

    it 'should add relationship has_part and source' do
      md_relationships_hash = @col.get_relationships_records

      added_rels = DRI::QualifiedDublinCore.find(md_relationships_hash[:parts].first).qdc_id
      added_rels.should =~ ['MAGOH01']
    end

    it 'should add relationship is_part_of' do
      md_relationships_hash = @obj.get_relationships_records

      added_rels = DRI::QualifiedDublinCore.find(md_relationships_hash[:container].first).qdc_id
      added_rels.should =~ ['MAGOH']
    end
  end
end
