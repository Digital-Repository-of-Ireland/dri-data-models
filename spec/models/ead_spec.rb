describe 'EncodedArchivalDescription' do
  context 'object methods' do

    before(:each) do
      allow(Resque).to receive(:enqueue)
      @header_xml = fixture('ead/collections/ead_header_dtd.xml')
      @ead_header = DRI::EadCollection.new
      @ead_header.update_metadata(DRI::Metadata::EncodedArchivalDescription.from_xml(@header_xml).to_xml, false)
    end

    after(:each) do
      @ead_header.delete unless @ead_header.new_record?
    end

    it 'should load the correct metadata class after initialisation' do
      @ead_col = DRI::EadCollection.new
      @ead_obj = DRI::EadComponent.new

      expect(@ead_col.descMetadata.class).to eq DRI::Metadata::EncodedArchivalDescription
      expect(@ead_obj.descMetadata.class).to eq DRI::Metadata::EncodedArchivalDescriptionComponent
    end

    it 'should load the correct metadata class after retrieving object from fedora' do
      @ead_header.save
      @collection = DRI::EadCollection.find_or_create(@ead_header.id)
      expect(@collection.descMetadata.class).to eq DRI::Metadata::EncodedArchivalDescription
    end

    it 'should find an existing object from fedora' do
      @ead_header.save
      @collection = DRI::EadCollection.find_or_create(@ead_header.noid)
      expect(@collection.new_record?).to eq false
    end

    it 'should create a new object if there is existing object for a given id' do
      @ead_header.save
      @collection = DRI::EadCollection.find_or_create('fake-ead-id')
      expect(@collection.new_record?).to eq true
    end

    it 'should be a kind of Base and EncodedArchivalDescription' do
      @ead_header.should be_kind_of(DRI::DigitalObject)
      @ead_header.should be_kind_of(DRI::EadCollection)
    end

    it 'should have the specified datastreams' do
      @ead_header.attached_files.keys.should include('descMetadata')
      @ead_header.descMetadata.should be_kind_of(DRI::Metadata::EncodedArchivalDescription)
      @ead_header.attached_files.keys.should include('fullMetadata')
      @ead_header.fullMetadata.should be_kind_of(DRI::Metadata::FullMetadata)
      @ead_header.attached_files.keys.should include('properties')
      @ead_header.properties.should be_kind_of(DRI::Metadata::Properties)
    end

    it 'should have the correct metadata type after a reload' do
      @ead_header.save
      @ead_header.descMetadata.should be_kind_of(DRI::Metadata::EncodedArchivalDescription)

      @ead_header.reload
      @ead_header.descMetadata.should be_kind_of(DRI::Metadata::EncodedArchivalDescription)
    end

    it 'should have namespaces removed from the ead datastream' do
      @ead_header = DRI::EadCollection.new
      @header_xml = fixture('ead/collections/ead_header.xml')
      @ead_header.update_metadata DRI::Metadata::EncodedArchivalDescription.from_xml(@header_xml).to_xml

      ead_namespace = {'xmlns:ead' => 'urn:isbn:1-931666-22-9'}
      expect(@ead_header.descMetadata.ng_xml.namespaces).not_to include(ead_namespace)
    end

    it "should add collection hierarchy information to the object\'s solr document" do
      @component = DRI::EadComponent.new
      @component.identifier = ['IE/NIVAL KDW-C']
      @component.identifier_id = 'KDW-C'
      @component.country_code = 'IE'
      @component.repository_code = 'IE-DuNIV'
      @component.creator = {display: ['Creator 1'], role: ['institution'], tag: ['persname']}
      @component.ead_level = 'otherlevel'
      @component.ead_level_other = 'Subcollection'
      @component.title = ['The test title']
      @component.desc_scope_content = ['This is a test description for the object.']
      #@component.type = ['Manuscript']
      @component.rights = ['This is a statement about the rights associated with this object']
      @component.creation_date = {display: ['2000-2010'], datechar: ['creation'], normal: ['20000101/20101231']}
      @component.language = {langcode: ['eng'], text: ['English']}
      @component.save

      @ead_header.governed_items << @component
      @ead_header.save

      collection_keys = ['root_collection_id_sim', 'root_collection_id_tesim', 'root_collection_sim',
                         'root_collection_tesim', 'is_collection_sim', 'is_collection_tesim']

      component_keys = ['ancestor_title_sim', 'ancestor_title_tesim', 'ancestor_id_tesim', 'ancestor_id_sim',
                        'governing_id_sim', 'collection_id_sim', 'collection_id_tesim', 'collection_sim',
                        'collection_tesim', 'root_collection_id_sim', 'root_collection_id_tesim', 'root_collection_sim',
                        'root_collection_tesim', 'is_collection_sim', 'is_collection_tesim', 'is_first_sibling_tesim', 'isGovernedBy_ssim']

      expect(@ead_header.collections_to_solr.keys).to match_array(collection_keys)
      expect(@ead_header.collections_to_solr).not_to have_key(ActiveFedora.index_field_mapper.solr_name('is_first_sibling', :stored_searchable))

      expect(@component.collections_to_solr.keys).to match_array(component_keys)
      expect(@component.collections_to_solr).to include(ActiveFedora.index_field_mapper.solr_name('is_first_sibling', :stored_searchable) => '1')
    end

    it "should add file metadata information to the object\'s solr document" do
      allow_any_instance_of(DRI::Asset::MimeTypes).to receive(:audio?).and_return(true)
      allow_any_instance_of(DRI::Asset::MimeTypes).to receive(:video?).and_return(true)
      allow_any_instance_of(DRI::Asset::MimeTypes).to receive(:image?).and_return(true)
      allow_any_instance_of(DRI::Asset::MimeTypes).to receive(:text?).and_return(true)
      allow_any_instance_of(DRI::Asset::MimeTypes).to receive(:pdf?).and_return(true)
      allow_any_instance_of(DRI::Asset::MimeTypes).to receive(:threeD?).and_return(true)

      file_md_keys = ['width_isim', 'width_sim', 'height_isim', 'height_sim', 'area_isim', 'area_sim',
                      'channels_isim', 'channels_sim', 'bit_depth_isim', 'bit_depth_sim', 'sample_rate_isim',
                      'sample_rate_sim', 'file_type_tesim', 'file_type_sim', 'mime_type_tesim', 'mime_type_sim',
                      'file_type_display_tesim', 'file_type_display_sim', 'file_format_tesim', 'file_format_sim', 'file_count_isi',
                      "file_size_isim", "file_size_sim", "file_size_total_isi"]

      @component = DRI::EadComponent.new
      @component.identifier = ['IE/NIVAL KDW-C']
      @component.identifier_id = 'KDW-C'
      @component.country_code = 'IE'
      @component.repository_code = 'IE-DuNIV'
      @component.creator = {display: ['Creator 1'], role: ['institution'], tag: ['persname']}
      @component.ead_level = 'otherlevel'
      @component.ead_level_other = 'Subcollection'
      @component.title = ['The test title']
      @component.desc_scope_content = ['This is a test description for the object.']
      @component.type = ['Manuscript']
      @component.rights = ['This is a statement about the rights associated with this object']
      @component.creation_date = {display: ['2000-2010'], normal: ['20000101/20101231']}
      @component.language = {langcode: ['eng'], text: ['English']}
      @component.generic_files = [DRI::GenericFile.create]
      @component.save

      #expect(@ead_header.file_metadata_to_solr.keys).to match_array(file_md_keys)
      expect(@ead_header.file_metadata_to_solr).to include(ActiveFedora.index_field_mapper.solr_name('file_type', :stored_searchable) => ['collection'])

      expect(@component.file_metadata_to_solr.keys).to match_array(file_md_keys)
    end

    it "should add object type information to the object\'s solr document" do
      object_type_keys = %w(object_type_sim object_type_ssm)

      @component = DRI::EadComponent.new
      @component.identifier = ['IE/NIVAL KDW-C']
      @component.identifier_id = 'KDW-C'
      @component.country_code = 'IE'
      @component.repository_code = 'IE-DuNIV'
      @component.creator = {display: ['Creator 1'], role: ['institution'], tag: ['persname']}
      @component.ead_level = 'otherlevel'
      @component.ead_level_other = 'Subcollection'
      @component.title = ['The test title']
      @component.desc_scope_content = ['This is a test description for the object.']
      @component.type = ['Manuscript']
      @component.rights = ['This is a statement about the rights associated with this object']
      @component.creation_date = {display: ['2000-2010'], normal: ['20000101/20101231']}
      @component.language = {langcode: ['eng'], text: ['English']}

      solr_field = ActiveFedora.index_field_mapper.solr_name('object_type', :displayable)

      expect(@ead_header.object_types_to_solr.keys).to match_array(object_type_keys)
      expect(@ead_header.object_types_to_solr).to include(solr_field => ['Collection'])

      expect(@component.object_types_to_solr.keys).to match_array(object_type_keys)
      expect(@component.object_types_to_solr).to have_key(solr_field)
      expect(@component.object_types_to_solr[solr_field]).to match_array(['Manuscript'])

      @component.type = []
      expect(@component.object_types_to_solr[solr_field]).to match_array(['Collection', 'Subcollection'])
    end
  end

  context 'synchronize parent metadata' do
    before(:each) do
      allow(Resque).to receive(:enqueue_to)

      @ead_xml = fixture('ead/updates/ead.xml')
      @ead_root = DRI::EadCollection.new
      @ead_root.update_metadata(DRI::Metadata::EncodedArchivalDescription.from_xml(@ead_xml).to_xml, false)
      @ead_root.save

      @series_xml = fixture('ead/updates/component_series.xml')
      @ead_series = DRI::EadComponent.new
      @ead_series.update_metadata(DRI::Metadata::EncodedArchivalDescription.from_xml(@series_xml).to_xml, false)
      @ead_series.save

      @file_xml = fixture('ead/updates/component_file.xml')
      @ead_file = DRI::EadComponent.new
      @ead_file.update_metadata(DRI::Metadata::EncodedArchivalDescription.from_xml(@file_xml).to_xml, false)
      @ead_file.save

      @item_xml = fixture('ead/updates/component_item.xml')
      @ead_item = DRI::EadComponent.new
      @ead_item.update_metadata(DRI::Metadata::EncodedArchivalDescription.from_xml(@item_xml).to_xml, false)
      @ead_item.save

      @ead_file.governed_items << @ead_item
      @ead_file.save
      @ead_series.governed_items << @ead_file
      @ead_series.save
      @ead_root.governed_items << @ead_series
      @ead_root.save

      @collection = DRI::EadCollection.new
      @collection.identifier = ['IE/NIVAL KDW']
      @collection.identifier_id = 'KDW'
      @collection.country_code = 'IE'
      @collection.repository_code = 'IE-DuNIV'

      @attributes_hash = {
          title: ['The test title'],
          creator: {display: ['Creator 1', 'Creator no role'], role: ['institution', ''], tag: ['persname', 'name']},
          desc_scope_content: ['This is a test description for the object.'],
          rights: ['This is a statement about the rights associated with this object'],
          creation_date: {display: ['2000-2010'], normal: ['20000101/20101231']},
          language: {langcode: ['eng'], text: ['English']}
      }
    end

    after(:each) do
      @ead_item.delete unless @ead_item.new_record?
      @ead_file.delete unless @ead_file.new_record?
      @ead_series.delete unless @ead_series.new_record?
      @ead_root.delete unless @ead_root.new_record?
      @collection.delete unless @collection.new_record?
    end

    it "should update the object\'s fullMetadata ds when updating object's metadata" do
      # via update_attributes
      @collection.attributes = @attributes_hash
      expect(@collection.trigger_update).to be true
      @collection.save
      expect(@collection.fullMetadata.to_xml).to eq(@collection.descMetadata.to_xml)
    end

    it "should not update the object\'s fullMetadata if no editable attributes are modified" do
      # via update_attributes
      @collection.attributes = {'ingest_files_from_metadata' => 'false'}
      expect(@collection.trigger_update).to be false
      expect_any_instance_of(DRI::EadCollection).not_to receive(:update_full_metadata)
      @collection.save
    end

    it "should update parents\' fullMetadata when updating object's metadata" do
      @ead_item.attributes = @attributes_hash
      @ead_item.save
      result = @ead_item.descMetadata.update_parent_metadata(@ead_file, @ead_item.fullMetadata)
      expect(result).to eq(true)
      result = @ead_file.descMetadata.update_parent_metadata(@ead_series, @ead_file.fullMetadata)
      expect(result).to eq(true)
      result = @ead_series.descMetadata.update_parent_metadata(@ead_root, @ead_series.fullMetadata)
      expect(result).to eq(true)

      query = "//*[did/unitid[@repositorycode='#{@ead_item.repository_code}' and @countrycode='#{@ead_item.country_code}' and text()='#{@ead_item.identifier.first}']]"
      node = @ead_root.fullMetadata.ng_xml.at(query)

      expect(node.at('did/unittitle').content).to eq(@ead_item.title.first)
      creators = ''
      node.search('did/origination/*').each { |n| creators << n.content }
      expect(creators).to eq(@ead_item.creator * '')
      expect(node.at('userestrict').content).to eq(@ead_item.rights.first)
      expect(node.at('did/unitdate[@datechar="creation"]').content).to eq('2000-2010')
      expect(node.at('did/langmaterial/language').content).to eq(@ead_item.language.first)
    end

    #it "should not update parents\' fullMetadata when there are no updates for the child object" do
    #  result = @ead_series.descMetadata.update_parent_metadata(@ead_series.governing_collection, @ead_series.fullMetadata)
    #  expect(result).to eq("update_parent_metadata for #{@ead_series.governing_collection.id}: No differences in fullMetadata")
    #end

    #it "should also update parents\' fullMetadata if using EAD XSD and namespace prefixes" do
    #  @ead_xml_ns = fixture('ead/updates/ead_ns.xml')
    #  @ead_ns = DRI::EadCollection.new
    #  @ead_ns.update_metadata(DRI::Metadata::EncodedArchivalDescription.from_xml(@ead_xml_ns).to_xml, false)
    #  @ead_ns.save

    #  @series_xml_ns = fixture('ead/updates/component_series_ns.xml')
    #  @ead_series_ns = DRI::EadComponent.new
    #  @ead_series_ns.update_metadata(DRI::Metadata::EncodedArchivalDescription.from_xml(@series_xml_ns).to_xml, false)
    #  @ead_series_ns.save

    #  @ead_ns.governed_items << @ead_series_ns
    #  @ead_ns.save

    #  @ead_series_ns.attributes = @attributes_hash
    #  expect(@ead_series_ns.trigger_update).to be true
    #  @ead_series_ns.save
    #  @ead_series_ns.descMetadata.update_parent_metadata(@ead_series_ns.governing_collection, @ead_series_ns.fullMetadata)

    #  query = "//*[ead:did/ead:unitid[@repositorycode='#{@ead_series_ns.repository_code}' and @countrycode='#{@ead_series_ns.country_code}' and text()='#{@ead_series_ns.identifier.first}']]"
    #  node = @ead_ns.fullMetadata.ng_xml.at(query)
    #  expect(node.xpath('ead:did/ead:unittitle', {'xmlns:ead' => 'urn:isbn:1-931666-22-9'}).first.content).to eq(@ead_series_ns.title.first)
    #  creators = ''
    #  node.xpath('ead:did/ead:origination/*', {'xmlns:ead' => 'urn:isbn:1-931666-22-9'}).each { |n| creators << n.content }
    #  expect(creators).to eq(@ead_series_ns.creator * '')
    #  expect(node.xpath('ead:userestrict', {'xmlns:ead' => 'urn:isbn:1-931666-22-9'}).first.content).to eq(@ead_series_ns.rights.first)
    #  expect(node.xpath('ead:did/ead:unitdate[@datechar="creation"]', {'xmlns:ead' => 'urn:isbn:1-931666-22-9'}).first.content).to eq('2000-2010')
    #  expect(node.xpath('ead:did/ead:langmaterial/ead:language', {'xmlns:ead' => 'urn:isbn:1-931666-22-9'}).first.content).to eq(@ead_series_ns.language.first)

    #  @ead_series_ns.delete
    #  @ead_ns.delete
    #end

    it 'should update root collection metadata using EAD XSD' do
      @ead_xml_ns = fixture('ead/updates/ead_ns.xml')
      @ead_ns = DRI::EadCollection.new
      @ead_ns.update_metadata(DRI::Metadata::EncodedArchivalDescription.from_xml(@ead_xml_ns).to_xml, false)
      @ead_ns.save

      @ead_ns.attributes = @attributes_hash
      expect(@ead_ns.trigger_update).to be true
      @ead_ns.save
      expect(@ead_ns.trigger_update).to be false

      node = @ead_ns.fullMetadata.ng_xml.root

      expect(node.xpath('ead:archdesc/ead:did/ead:unittitle', {'xmlns:ead' => 'urn:isbn:1-931666-22-9'}).first.content).to eq(@ead_ns.title.first)
      creators = ''
      node.xpath('ead:archdesc/ead:did/ead:origination/*', {'xmlns:ead' => 'urn:isbn:1-931666-22-9'}).each { |n| creators << n.content }
      expect(creators).to eq(@ead_ns.creator * '')
      expect(@ead_ns.rights).to eq(@attributes_hash[:rights])
      expect(node.xpath('ead:archdesc/ead:did/ead:unitdate[@datechar="creation"]', {'xmlns:ead' => 'urn:isbn:1-931666-22-9'}).first.content).to eq('2000-2010')
      expect(node.xpath('ead:archdesc/ead:did/ead:langmaterial/ead:language', {'xmlns:ead' => 'urn:isbn:1-931666-22-9'}).first.content).to eq(@ead_ns.language.first)

      @ead_ns.delete
    end

    it 'should update root collection metadata using EAD DTD' do
      @ead_root.attributes = @attributes_hash
      expect(@ead_root.trigger_update).to be true
      @ead_root.save
      expect(@ead_root.trigger_update).to be false

      node = @ead_root.fullMetadata.ng_xml.root
      expect(node.at('archdesc/did/unittitle').content).to eq(@ead_root.title.first)
      creators = ''
      node.search('archdesc/did/origination/*').each { |n| creators << n.content }
      expect(creators).to eq(@ead_root.creator * '')
      expect(@ead_root.rights).to eq(@attributes_hash[:rights])
      expect(node.at('archdesc/did/unitdate[@datechar="creation"]').content).to eq('2000-2010')
      expect(node.at('archdesc/did/langmaterial/language').content).to eq(@ead_root.language.first)
    end
  end

  context 'update attributes methods' do
    # Before each test create test objects
    before(:each) do
      allow(Resque).to receive(:enqueue)

      @header_xml = fixture('ead/collections/ead_header_dtd.xml')
      @ead_header = DRI::EadCollection.new
      @ead_header.update_metadata(DRI::Metadata::EncodedArchivalDescription.from_xml(@header_xml).to_xml, false)

      @collection = DRI::EadCollection.new
      @collection.identifier = ['IE/NIVAL KDW']
      @collection.identifier_id = 'KDW'
      @collection.country_code = 'IE'
      @collection.repository_code = 'IE-DuNIV'
      @component = DRI::EadComponent.new
      @component.identifier = ['IE/NIVAL KDW']
      @component.identifier_id = 'KDW'
      @component.country_code = 'IE'
      @component.repository_code = 'IE-DuNIV'

      @attributes_hash = {
          title: ['The test title'],
          creator: { display: ['Creator 1', 'Creator no role'], role: ['institution', ''], tag: ['persname', 'name'] },
          contributor: ['Contributor 1'],
          desc_scope_content: ['This is a test description for the object.'],
          desc_abstract: ['This is a test abstract for the object.'],
          desc_biog_hist: ['This is a test biographical history for the object.'],
          rights: ['This is a statement about the rights associated with this object'],
          type: ['Collection'],
          published_date: { display: ['2015'], normal: ['20150101'] },
          creation_date: { display: ['2000-2010'], normal: ['20000101/20101231'] },
          name_coverage: { display: ['Designer 1', 'Photographer 1'], role: ['designer', 'photographer'], tag: ['persname', 'corpname'] },
          geogname_coverage_access: { type: ['', 'dcterms:Point', 'logainm'], display: ['Dublin', 'name=Dublin; east=-6.266155; north=53.350140;', 'http://example.org/1234'] },
          temporal_coverage: { normal: ['2005'], datechar: ['coverage'], display: ['c. 2005'] },
          subject: ['Ireland', 'something else'],
          name_subject: ['subject name'],
          persname_subject: ['subject persname'],
          corpname_subject: ['subject corpname'],
          geogname_subject: ['subject geogname'],
          famname_subject: ['subject famname'],
          publisher: ['Publisher 1'],
          related_material: ['http://example.org/relmat'],
          alternative_form: ['http://example.org/altform'],
          language: { langcode: ['eng'], text: ['English'] },
          format: ['395 files']
      }
    end

    # After each test clean-up
    after(:each) do
      @ead_header.delete unless @ead_header.new_record?
      @collection.delete unless @collection.new_record?
    end

    it 'should update the object\'s attributes (EAD collection)' do
      # via update_attributes
      @collection.attributes = @attributes_hash

      expect(@collection.title).to match_array(['The test title'])
      expect(@collection.creator).to match_array(['Creator 1', 'Creator no role'])
      expect(@collection.contributor).to match_array(['Contributor 1'])
      expect(@collection.description).to match_array(['This is a test description for the object.'])
      expect(@collection.desc_scope_content).to match_array(['This is a test description for the object.'])
      expect(@collection.desc_abstract).to eq('This is a test abstract for the object.')
      expect(@collection.desc_biog_hist).to match_array(['This is a test biographical history for the object.'])
      expect(@collection.rights).to match_array(['This is a statement about the rights associated with this object'])
      expect(@collection.publisher).to match_array(['Publisher 1'])
      expect(@collection.geographical_coverage).to match_array(['Dublin', 'name=Dublin; east=-6.266155; north=53.350140;', 'http://example.org/1234'])
      expect(@collection.subject).to match_array(['Ireland', 'something else'])
      expect(@collection.creation_date).to match_array(['2000-2010'])
      expect(@collection.published_date).to match_array(['2015'])
      expect(@collection.name_coverage).to match_array(['Designer 1', 'Photographer 1'])
      expect(@collection.temporal_coverage).to match_array(['c. 2005'])
      expect(@collection.name_subject).to match_array(['subject name'])
      expect(@collection.persname_subject).to match_array(['subject persname'])
      expect(@collection.corpname_subject).to match_array(['subject corpname'])
      expect(@collection.geogname_subject).to match_array(['subject geogname'])
      expect(@collection.famname_subject).to match_array(['subject famname'])
      expect(@collection.geogname_coverage_access).to match_array(['Dublin', 'name=Dublin; east=-6.266155; north=53.350140;', 'http://example.org/1234'])
      expect(@collection.type).to match_array(['Collection'])
      expect(@collection.related_material).to match_array(['http://example.org/relmat'])
      expect(@collection.alternative_form).to match_array(['http://example.org/altform'])
      expect(@collection.language).to match_array(['English'])

      # via attribute assignment
      @collection.title = ['The test title']
      @collection.creator = { display: ['Creator 2'], role: ['designer'], tag: ['corpname'] }
      @collection.contributor = ['Contributor 1']
      @collection.publisher = ['Publisher 1']
      @collection.desc_scope_content = ['This is a test description for the object.']
      @collection.desc_abstract = ['This is a test abstract for the object.']
      @collection.desc_biog_hist = ['This is a test biographical history for the object.']
      @collection.type = ['Collection']
      @collection.rights = ['This is a statement about the rights associated with this object']
      @collection.published_date = { display: ['2015'], normal: ['20150101'] }
      @collection.creation_date = { display: ['2000-2010'], normal: ['20000101/20101231'] }
      @collection.name_coverage = { display: ['Designer 2', 'Transcriber 1'], role: ['designer', 'transcriber'], tag: ['persname', 'name'] }
      @collection.temporal_coverage = { normal: ['2005'], datechar: ['coverage'], display: ['c. 2005'] }
      @collection.subject = ['Ireland', 'something else']
      @collection.geogname_coverage_access = { type: ['', 'dcterms:Point', 'logainm'], display: ['Dublin', 'name=Dublin; east=-6.266155; north=53.350140;', 'http://example.org/1234'] }
      @collection.name_subject = ['subject name']
      @collection.persname_subject = ['subject persname']
      @collection.corpname_subject = ['subject corpname']
      @collection.geogname_subject = ['subject geogname']
      @collection.famname_subject = ['subject famname']
      @collection.related_material = ['http://example.org/relmat']
      @collection.alternative_form = ['http://example.org/altform']
      @collection.language = { langcode: ['eng'], text: ['English'] }

      expect(@collection.title).to match_array(['The test title'])
      expect(@collection.creator).to match_array(['Creator 2'])
      expect(@collection.contributor).to match_array(['Contributor 1'])
      expect(@collection.description).to match_array(['This is a test description for the object.'])
      expect(@collection.desc_scope_content).to match_array(['This is a test description for the object.'])
      expect(@collection.desc_abstract).to eq('This is a test abstract for the object.')
      expect(@collection.desc_biog_hist).to match_array(['This is a test biographical history for the object.'])
      expect(@collection.rights).to match_array(['This is a statement about the rights associated with this object'])
      expect(@collection.publisher).to match_array(['Publisher 1'])
      expect(@collection.geographical_coverage).to match_array(['Dublin', 'name=Dublin; east=-6.266155; north=53.350140;', 'http://example.org/1234'])
      expect(@collection.subject).to match_array(['Ireland', 'something else'])
      expect(@collection.creation_date).to match_array(['2000-2010'])
      expect(@collection.published_date).to match_array(['2015'])
      expect(@collection.name_coverage).to match_array(['Designer 2', 'Transcriber 1'])
      expect(@collection.temporal_coverage).to match_array(['c. 2005'])
      expect(@collection.name_subject).to match_array(['subject name'])
      expect(@collection.persname_subject).to match_array(['subject persname'])
      expect(@collection.corpname_subject).to match_array(['subject corpname'])
      expect(@collection.geogname_subject).to match_array(['subject geogname'])
      expect(@collection.famname_subject).to match_array(['subject famname'])
      expect(@collection.geogname_coverage_access).to match_array(['Dublin', 'name=Dublin; east=-6.266155; north=53.350140;', 'http://example.org/1234'])
      expect(@collection.type).to match_array(['Collection'])
      expect(@collection.related_material).to match_array(['http://example.org/relmat'])
      expect(@collection.alternative_form).to match_array(['http://example.org/altform'])
      expect(@collection.language).to match_array(['English'])
    end

    it 'should update the object\'s attributes (EAD component)' do
      # via update_attributes
      @component.attributes = @attributes_hash

      expect(@component.title).to match_array(['The test title'])
      expect(@component.creator).to match_array(['Creator 1', 'Creator no role'])
      expect(@component.contributor).to match_array(['Contributor 1'])
      expect(@component.description).to match_array(['This is a test description for the object.'])
      expect(@component.desc_scope_content).to match_array(['This is a test description for the object.'])
      expect(@component.desc_abstract).to eq('This is a test abstract for the object.')
      expect(@component.desc_biog_hist).to match_array(['This is a test biographical history for the object.'])
      expect(@component.rights).to match_array(['This is a statement about the rights associated with this object'])
      expect(@component.publisher).to match_array(['Publisher 1'])
      expect(@component.geographical_coverage).to match_array(['Dublin', 'name=Dublin; east=-6.266155; north=53.350140;', 'http://example.org/1234'])
      expect(@component.subject).to match_array(['Ireland', 'something else'])
      expect(@component.creation_date).to match_array(['2000-2010'])
      expect(@component.published_date).to match_array(['2015'])
      expect(@component.name_coverage).to match_array(['Designer 1', 'Photographer 1'])
      expect(@component.temporal_coverage).to match_array(['c. 2005'])
      expect(@component.name_subject).to match_array(['subject name'])
      expect(@component.persname_subject).to match_array(['subject persname'])
      expect(@component.corpname_subject).to match_array(['subject corpname'])
      expect(@component.geogname_subject).to match_array(['subject geogname'])
      expect(@component.famname_subject).to match_array(['subject famname'])
      expect(@component.geogname_coverage_access).to match_array(['Dublin', 'name=Dublin; east=-6.266155; north=53.350140;', 'http://example.org/1234'])
      expect(@component.type).to match_array(['Collection'])
      expect(@component.related_material).to match_array(['http://example.org/relmat'])
      expect(@component.alternative_form).to match_array(['http://example.org/altform'])
      expect(@component.language).to match_array(['English'])

      # via attribute assignment
      @component.title = ['The test title']
      @component.creator = { display: ['Creator 2'], role: ['studio'], tag: ['corpname'] }
      @component.contributor = ['Contributor 1']
      @component.publisher = ['Publisher 1']
      @component.desc_scope_content = ['This is a test description for the object.']
      @component.desc_abstract = ['This is a test abstract for the object.']
      @component.desc_biog_hist = ['This is a test biographical history for the object.']
      @component.type = ['Collection']
      @component.rights = ['This is a statement about the rights associated with this object']
      @component.published_date = { display: ['2015'], normal: ['20150101'] }
      @component.creation_date = { display: ['2000-2010'], normal: ['20000101/20101231'] }
      @component.name_coverage = { display: ['Designer 2', 'Transcriber 1'], role: ['designer', 'transcriber'], tag: ['persname', 'name'] }
      @component.temporal_coverage = { normal: ['2005'], datechar: ['coverage'], display: ['c. 2005'] }
      @component.subject = ['Ireland', 'something else']
      @component.geogname_coverage_access = { type: ['', 'dcterms:Point', 'logainm'], display: ['Dublin', 'name=Dublin; east=-6.266155; north=53.350140;', 'http://example.org/1234'] }
      @component.name_subject = ['subject name']
      @component.persname_subject = ['subject persname']
      @component.corpname_subject = ['subject corpname']
      @component.geogname_subject = ['subject geogname']
      @component.famname_subject = ['subject famname']
      @component.related_material = ['http://example.org/relmat']
      @component.alternative_form = ['http://example.org/altform']
      @component.language = {langcode: ['eng'], text: ['English']}

      expect(@component.title).to match_array(['The test title'])
      expect(@component.creator).to match_array(['Creator 2'])
      expect(@component.contributor).to match_array(['Contributor 1'])
      expect(@component.description).to match_array(['This is a test description for the object.'])
      expect(@component.desc_scope_content).to match_array(['This is a test description for the object.'])
      expect(@component.desc_abstract).to eq('This is a test abstract for the object.')
      expect(@component.desc_biog_hist).to match_array(['This is a test biographical history for the object.'])
      expect(@component.rights).to match_array(['This is a statement about the rights associated with this object'])
      expect(@component.contributor).to match_array(['Contributor 1'])
      expect(@component.publisher).to match_array(['Publisher 1'])
      expect(@component.geographical_coverage).to match_array(['Dublin', 'name=Dublin; east=-6.266155; north=53.350140;', 'http://example.org/1234'])
      expect(@component.subject).to match_array(['Ireland', 'something else'])
      expect(@component.creation_date).to match_array(['2000-2010'])
      expect(@component.published_date).to match_array(['2015'])
      expect(@component.name_coverage).to match_array(['Designer 2', 'Transcriber 1'])
      expect(@component.temporal_coverage).to match_array(['c. 2005'])
      expect(@component.name_subject).to match_array(['subject name'])
      expect(@component.persname_subject).to match_array(['subject persname'])
      expect(@component.corpname_subject).to match_array(['subject corpname'])
      expect(@component.geogname_subject).to match_array(['subject geogname'])
      expect(@component.famname_subject).to match_array(['subject famname'])
      expect(@component.geogname_coverage_access).to match_array(['Dublin', 'name=Dublin; east=-6.266155; north=53.350140;', 'http://example.org/1234'])
      expect(@component.type).to match_array(['Collection'])
      expect(@component.related_material).to match_array(['http://example.org/relmat'])
      expect(@component.alternative_form).to match_array(['http://example.org/altform'])
      expect(@component.language).to match_array(['English'])
    end

    it 'should return a hash of attributes for form update (collection)' do
      @collection.attributes = @attributes_hash

      terms_hash = @collection.retrieve_hash_attributes

      expect(terms_hash[:title]).to match_array(['The test title'])
      expect(terms_hash[:creator]).to include(display: ['Creator 1', 'Creator no role'], role: ['institution', ''], tag: ['persname', 'name'])
      expect(terms_hash[:contributor]).to match_array(['Contributor 1'])
      expect(terms_hash[:desc_scope_content]).to match_array(['This is a test description for the object.'])
      expect(terms_hash[:desc_abstract]).to match_array(['This is a test abstract for the object.'])
      expect(terms_hash[:desc_biog_hist]).to match_array(['This is a test biographical history for the object.'])
      expect(terms_hash[:rights]).to match_array(['This is a statement about the rights associated with this object'])
      expect(terms_hash[:publisher]).to match_array(['Publisher 1'])
      expect(terms_hash[:subject]).to match_array(['Ireland', 'something else'])
      expect(terms_hash[:creation_date]).to include(display: ['2000-2010'], normal: ['20000101/20101231'])
      expect(terms_hash[:published_date]).to include(display: ['2015'], normal: ['20150101'])
      expect(terms_hash[:name_coverage]).to include(display: ['Designer 1', 'Photographer 1'], role: ['designer', 'photographer'], tag: ['persname', 'corpname'])
      expect(terms_hash[:temporal_coverage]).to include(normal: ['2005'], datechar: ['coverage'], display: ['c. 2005'])
      expect(terms_hash[:name_subject]).to match_array(['subject name'])
      expect(terms_hash[:persname_subject]).to match_array(['subject persname'])
      expect(terms_hash[:corpname_subject]).to match_array(['subject corpname'])
      expect(terms_hash[:geogname_subject]).to match_array(['subject geogname'])
      expect(terms_hash[:famname_subject]).to match_array(['subject famname'])
      expect(terms_hash[:geogname_coverage_access]).to include(display: ['Dublin', 'name=Dublin; east=-6.266155; north=53.350140;', 'http://example.org/1234'], type: ['', 'dcterms:Point', 'logainm'])
      expect(terms_hash[:type]).to match_array(['Collection'])
      expect(terms_hash[:related_material]).to match_array(['http://example.org/relmat'])
      expect(terms_hash[:alternative_form]).to match_array(['http://example.org/altform'])
      expect(terms_hash[:language]).to include(langcode: ['eng'], text: ['English'])
      expect(terms_hash[:format]).to match_array(['395 files'])
    end

    it 'should return a hash of attributes for form update (component)' do
      @component.attributes = @attributes_hash

      terms_hash = @component.retrieve_hash_attributes

      expect(terms_hash[:title]).to match_array(['The test title'])
      expect(terms_hash[:creator]).to include(display: ['Creator 1', 'Creator no role'], role: ['institution', ''], tag: ['persname', 'name'])
      expect(terms_hash[:contributor]).to match_array(['Contributor 1'])
      expect(terms_hash[:desc_scope_content]).to match_array(['This is a test description for the object.'])
      expect(terms_hash[:desc_abstract]).to match_array(['This is a test abstract for the object.'])
      expect(terms_hash[:desc_biog_hist]).to match_array(['This is a test biographical history for the object.'])
      expect(terms_hash[:rights]).to match_array(['This is a statement about the rights associated with this object'])
      expect(terms_hash[:publisher]).to match_array(['Publisher 1'])
      expect(terms_hash[:subject]).to match_array(['Ireland', 'something else'])
      expect(terms_hash[:creation_date]).to include(display: ['2000-2010'], normal: ['20000101/20101231'])
      expect(terms_hash[:published_date]).to include(display: ['2015'], normal: ['20150101'])
      expect(terms_hash[:name_coverage]).to include(display: ['Designer 1', 'Photographer 1'], role: ['designer', 'photographer'], tag: ['persname', 'corpname'])
      expect(terms_hash[:temporal_coverage]).to include(normal: ['2005'], datechar: ['coverage'], display: ['c. 2005'])
      expect(terms_hash[:name_subject]).to match_array(['subject name'])
      expect(terms_hash[:persname_subject]).to match_array(['subject persname'])
      expect(terms_hash[:corpname_subject]).to match_array(['subject corpname'])
      expect(terms_hash[:geogname_subject]).to match_array(['subject geogname'])
      expect(terms_hash[:famname_subject]).to match_array(['subject famname'])
      expect(terms_hash[:geogname_coverage_access]).to include(type: ['', 'dcterms:Point', 'logainm'], display: ['Dublin', 'name=Dublin; east=-6.266155; north=53.350140;', 'http://example.org/1234'])
      expect(terms_hash[:type]).to match_array(['Collection'])
      expect(terms_hash[:related_material]).to match_array(['http://example.org/relmat'])
      expect(terms_hash[:alternative_form]).to match_array(['http://example.org/altform'])
      expect(terms_hash[:language]).to include(langcode: ['eng'], text: ['English'])
      expect(terms_hash[:format]).to match_array(['395 files'])
    end
  end
end
