
describe 'EncodedArchivalDescription' do
  context 'object methods' do
    before(:each) do
      @header_xml = fixture("ead/collections/ead_header_dtd.xml")
      @ead_header = DRI::EncodedArchivalDescription.new :collection
      @ead_header.update_metadata(DRI::Metadata::EncodedArchivalDescription.from_xml(@header_xml).to_xml, false)
    end

    after(:each) do
      unless @ead_header.new_record?
        @ead_header.delete
      end
    end

    it "should find an existing object from fedora" do
      @ead_header.save
      @collection = DRI::EncodedArchivalDescription.find_or_create(@ead_header.id)
      expect(@collection.new_record?).to eq false
    end

    it "should create a new object if there is existing object for a given id" do
      @ead_header.save
      @collection = DRI::EncodedArchivalDescription.find_or_create('fake-id')
      expect(@collection.new_record?).to eq true
    end
    it "should be a kind of Batch and EncodedArchivalDescription" do
      @ead_header.should be_kind_of(DRI::Batch)
      @ead_header.should be_kind_of(DRI::EncodedArchivalDescription)
    end

    it "should have the specified datastreams" do
      @ead_header.attached_files.keys.should include(:descMetadata)
      @ead_header.descMetadata.should be_kind_of(DRI::Metadata::EncodedArchivalDescription)
      @ead_header.attached_files.keys.should include(:fullMetadata)
      @ead_header.fullMetadata.should be_kind_of(DRI::Metadata::FullMetadata)
      @ead_header.attached_files.keys.should include(:properties)
      @ead_header.properties.should be_kind_of(DRI::Metadata::Properties)
    end

    it "should have namespaces removed from the ead datastream" do
      @ead_header = DRI::EncodedArchivalDescription.new :collection
      @header_xml = fixture("ead/collections/ead_header.xml")
      @ead_header.update_metadata DRI::Metadata::EncodedArchivalDescription.from_xml(@header_xml).to_xml

      ead_namespace = {'xmlns:ead' => 'urn:isbn:1-931666-22-9'}
      expect(@ead_header.descMetadata.ng_xml.namespaces).not_to include(ead_namespace)
    end

    it "should add collection hierarchy information to the object's solr document" do
      @component = DRI::EncodedArchivalDescription.new(:component)
      @component.identifier = ['IE/NIVAL KDW-C']
      @component.identifier_id = 'KDW-C'
      @component.country_code = 'IE'
      @component.repository_code = 'IE-DuNIV'
      @component.creator = {:display => ['Creator 1'], :role => ['institution'], :tag => ['persname']}
      @component.title = ['The test title']
      @component.desc_scope_content = ['This is a test description for the object.']
      @component.type  = ['Manuscript']
      @component.rights = ['This is a statement about the rights associated with this object']
      @component.creation_date = {:display => ['2000-2010'], :datechar => ['creation'], :normal => ['20000101/20101231']}
      @component.language = {:langcode => ['en'], :text => ['English']}
      @component.save

      @ead_header.governed_items << @component
      @ead_header.save

      collection_keys = ["root_collection_id_sim", "root_collection_id_tesim", "root_collection_sim",
                         "root_collection_tesim", "is_collection_sim", "is_collection_tesim"]

      component_keys = ["ancestor_title_sim", "ancestor_title_tesim", "ancestor_id_tesim", "ancestor_id_sim",
                         "governing_id_sim", "collection_id_sim", "collection_id_tesim", "collection_sim",
                         "collection_tesim", "root_collection_id_sim", "root_collection_id_tesim", "root_collection_sim",
                         "root_collection_tesim", "is_collection_sim", "is_collection_tesim", "is_first_sibling_tesim"]

      expect(@ead_header.collections_to_solr.keys).to match_array(collection_keys)
      expect(@ead_header.collections_to_solr).not_to have_key(ActiveFedora::SolrQueryBuilder.solr_name('is_first_sibling', :stored_searchable))

      expect(@component.collections_to_solr.keys).to match_array(component_keys)
      expect(@component.collections_to_solr).to include(ActiveFedora::SolrQueryBuilder.solr_name('is_first_sibling', :stored_searchable) => '1')
    end

    it "should add file metadata information to the object's solr document" do
      file_md_keys = ["width_isim", "width_sim", "height_isim", "height_sim", "area_isim", "area_sim",
                         "channels_isim", "channels_sim", "bit_depth_isim", "bit_depth_sim", "sample_rate_isim",
                         "sample_rate_sim", "file_type_tesim", "file_type_sim", "mime_type_tesim", "mime_type_sim",
                         "file_type_display_tesim", "file_type_display_sim", "file_format_tesim", "file_format_sim", "file_count_isi"]

      @component = DRI::EncodedArchivalDescription.new(:component)
      @component.identifier = ['IE/NIVAL KDW-C']
      @component.identifier_id = 'KDW-C'
      @component.country_code = 'IE'
      @component.repository_code = 'IE-DuNIV'
      @component.creator = {:display => ['Creator 1'], :role => ['institution'], :tag => ['persname']}
      @component.ead_level = 'otherlevel'
      @component.ead_level_other = 'Subcollection'
      @component.title = ['The test title']
      @component.desc_scope_content = ['This is a test description for the object.']
      @component.type  = ['Manuscript']
      @component.rights = ['This is a statement about the rights associated with this object']
      @component.creation_date = {:display => ['2000-2010'], :normal => ['20000101/20101231']}
      @component.language = {:langcode => ['en'], :text => ['English']}

      expect(@ead_header.file_metadata_to_solr.keys).to match_array(file_md_keys)
      expect(@ead_header.file_metadata_to_solr).to include(ActiveFedora::SolrQueryBuilder.solr_name('file_type', :stored_searchable) => ['collection'])

      expect(@component.file_metadata_to_solr.keys).to match_array(file_md_keys)
      expect(@component.file_metadata_to_solr).to include(ActiveFedora::SolrQueryBuilder.solr_name('file_type', :stored_searchable) => ['collection'])
    end

    it "should add object type information to the object's solr document" do
      object_type_keys = ["object_type_sim", "object_type_ssm"]

      @component = DRI::EncodedArchivalDescription.new(:component)
      @component.identifier = ['IE/NIVAL KDW-C']
      @component.identifier_id = 'KDW-C'
      @component.country_code = 'IE'
      @component.repository_code = 'IE-DuNIV'
      @component.creator = {:display => ['Creator 1'], :role => ['institution'], :tag => ['persname']}
      @component.ead_level = 'otherlevel'
      @component.ead_level_other = 'Subcollection'
      @component.title = ['The test title']
      @component.desc_scope_content = ['This is a test description for the object.']
      @component.type  = ['Manuscript']
      @component.rights = ['This is a statement about the rights associated with this object']
      @component.creation_date = {:display => ['2000-2010'], :normal => ['20000101/20101231']}
      @component.language = {:langcode => ['en'], :text => ['English']}

      solr_field = ActiveFedora::SolrQueryBuilder.solr_name('object_type', :displayable)

      expect(@ead_header.object_types_to_solr.keys).to match_array(object_type_keys)
      expect(@ead_header.object_types_to_solr).to include(solr_field => ['Collection'])

      expect(@component.object_types_to_solr.keys).to match_array(object_type_keys)
      expect(@component.object_types_to_solr).to have_key(solr_field)
      expect(@component.object_types_to_solr[solr_field]).to match_array(['Manuscript'])

      @component.type = []
      expect(@component.object_types_to_solr[solr_field]).to match_array(['Collection', 'Subcollection'])
    end
  end

  context 'update attributes methods' do
    # Before each test create test objects
    before(:each) do
      @header_xml = fixture("ead/collections/ead_header_dtd.xml")
      @ead_header = DRI::EncodedArchivalDescription.new :collection
      @ead_header.update_metadata DRI::Metadata::EncodedArchivalDescription.from_xml(@header_xml).to_xml

      @collection = DRI::EncodedArchivalDescription.new(:collection)
      @collection.identifier = ['IE/NIVAL KDW']
      @collection.identifier_id = 'KDW'
      @collection.country_code = 'IE'
      @collection.repository_code = 'IE-DuNIV'
      @component = DRI::EncodedArchivalDescription.new(:component)
      @component.identifier = ['IE/NIVAL KDW']
      @component.identifier_id = 'KDW'
      @component.country_code = 'IE'
      @component.repository_code = 'IE-DuNIV'

      @attributes_hash = {
          :title  => ['The test title'],
          :creator => {:display => ['Creator 1', 'Creator no role'], :role => ['institution', ''], :tag => ['persname', 'name']},
          :contributor => ['Contributor 1'],
          :desc_scope_content  => ['This is a test description for the object.'],
          :desc_abstract  => ['This is a test abstract for the object.'],
          :desc_biog_hist  => ['This is a test biographical history for the object.'],
          :rights  => ['This is a statement about the rights associated with this object'],
          :type  => ['Collection'],
          :published_date => {:display => ['2015'], :normal => ['20150101']},
          :creation_date => {:display => ['2000-2010'], :normal => ['20000101/20101231']},
          :name_coverage => {:display => ['Designer 1', 'Photographer 1'], :role => ['designer', 'photographer'], :tag => ['persname', 'corpname']},
          :geogname_coverage_access => {:type => ['', 'dcterms:Point', 'logainm'], :display => ['Dublin', 'name=Dublin; east=-6.266155; north=53.350140;', 'http://example.org/1234']},
          :temporal_coverage => {:normal => ['2005'], :datechar => ['coverage'], :display => ['c. 2005']},
          :subject  => ['Ireland','something else'],
          :name_subject  => ['subject name'],
          :persname_subject  => ['subject persname'],
          :corpname_subject  => ['subject corpname'],
          :geogname_subject  => ['subject geogname'],
          :famname_subject  => ['subject famname'],
          :publisher  => ['Publisher 1'],
          :related_material  => ['http://example.org/relmat'],
          :alternative_form  => ['http://example.org/altform'],
          :language => {:langcode => ['en'], :text => ['English']}
      }
    end

    # After each test clean-up
    after(:each) do
      if !@ead_header.new_record?
        @ead_header.delete
      end
      if !@collection.new_record?
        @collection.delete
      end
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
      expect(@collection.subject).to match_array(['Ireland','something else'])
      expect(@collection.creation_date).to match_array(['2000-2010'])
      expect(@collection.published_date).to match_array(['2015'])
      expect(@collection.name_coverage).to match_array( ["Designer 1", "Photographer 1"])
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
      @collection.creator = {:display => ['Creator 2'], :role => ['designer'], :tag => ['corpname']}
      @collection.contributor = ['Contributor 1']
      @collection.publisher  = ['Publisher 1']
      @collection.desc_scope_content = ['This is a test description for the object.']
      @collection.desc_abstract  = ['This is a test abstract for the object.']
      @collection.desc_biog_hist  = ['This is a test biographical history for the object.']
      @collection.type  = ['Collection']
      @collection.rights = ['This is a statement about the rights associated with this object']
      @collection.published_date = {:display => ['2015'], :normal => ['20150101']}
      @collection.creation_date = {:display => ['2000-2010'], :normal => ['20000101/20101231']}
      @collection.name_coverage = {:display => ['Designer 2', 'Transcriber 1'], :role => ['designer', 'transcriber'], :tag => ['persname', 'name']}
      @collection.temporal_coverage = {:normal => ['2005'], :datechar => ['coverage'], :display => ['c. 2005']}
      @collection.subject = ['Ireland','something else']
      @collection.geogname_coverage_access = {:type => ['', 'dcterms:Point', 'logainm'], :display => ['Dublin', 'name=Dublin; east=-6.266155; north=53.350140;', 'http://example.org/1234']}
      @collection.name_subject  = ['subject name']
      @collection.persname_subject  = ['subject persname']
      @collection.corpname_subject  = ['subject corpname']
      @collection.geogname_subject  = ['subject geogname']
      @collection.famname_subject  = ['subject famname']
      @collection.related_material  = ['http://example.org/relmat']
      @collection.alternative_form  = ['http://example.org/altform']
      @collection.language = {:langcode => ['en'], :text => ['English']}

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
      expect(@collection.subject).to match_array(['Ireland','something else'])
      expect(@collection.creation_date).to match_array(['2000-2010'])
      expect(@collection.published_date).to match_array(['2015'])
      expect(@collection.name_coverage).to match_array( ['Designer 2', 'Transcriber 1'])
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
      expect(@component.subject).to match_array(['Ireland','something else'])
      expect(@component.creation_date).to match_array(['2000-2010'])
      expect(@component.published_date).to match_array(['2015'])
      expect(@component.name_coverage).to match_array( ["Designer 1", "Photographer 1"])
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
      @component.creator = {:display => ['Creator 2'], :role => ['studio'], :tag => ['corpname']}
      @component.contributor  = ['Contributor 1']
      @component.publisher  = ['Publisher 1']
      @component.desc_scope_content = ['This is a test description for the object.']
      @component.desc_abstract  = ['This is a test abstract for the object.']
      @component.desc_biog_hist  = ['This is a test biographical history for the object.']
      @component.type  = ['Collection']
      @component.rights = ['This is a statement about the rights associated with this object']
      @component.published_date = {:display => ['2015'], :normal => ['20150101']}
      @component.creation_date = {:display => ['2000-2010'], :normal => ['20000101/20101231']}
      @component.name_coverage = {:display => ['Designer 2', 'Transcriber 1'], :role => ['designer', 'transcriber'], :tag => ['persname', 'name']}
      @component.temporal_coverage = {:normal => ['2005'], :datechar => ['coverage'], :display => ['c. 2005']}
      @component.subject = ['Ireland','something else']
      @component.geogname_coverage_access = {:type => ['', 'dcterms:Point', 'logainm'], :display => ['Dublin', 'name=Dublin; east=-6.266155; north=53.350140;', 'http://example.org/1234']}
      @component.name_subject  = ['subject name']
      @component.persname_subject  = ['subject persname']
      @component.corpname_subject  = ['subject corpname']
      @component.geogname_subject  = ['subject geogname']
      @component.famname_subject  = ['subject famname']
      @component.related_material  = ['http://example.org/relmat']
      @component.alternative_form  = ['http://example.org/altform']
      @component.language = {:langcode => ['en'], :text => ['English']}

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
      expect(@component.subject).to match_array(['Ireland','something else'])
      expect(@component.creation_date).to match_array(['2000-2010'])
      expect(@component.published_date).to match_array(['2015'])
      expect(@component.name_coverage).to match_array( ['Designer 2', 'Transcriber 1'])
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

    it "should return a hash of attributes for form update (collection)" do
      @collection.attributes = @attributes_hash

      terms_hash = @collection.get_hash_attributes

      expect(terms_hash[:title]).to match_array(['The test title'])
      expect(terms_hash[:creator]).to include(:display => ['Creator 1', 'Creator no role'], :role => ['institution', ''], :tag => ['persname', 'name'])
      expect(terms_hash[:contributor]).to match_array(['Contributor 1'])
      expect(terms_hash[:desc_scope_content]).to match_array(['This is a test description for the object.'])
      expect(terms_hash[:desc_abstract]).to match_array(['This is a test abstract for the object.'])
      expect(terms_hash[:desc_biog_hist]).to match_array(['This is a test biographical history for the object.'])
      expect(terms_hash[:rights]).to match_array(['This is a statement about the rights associated with this object'])
      expect(terms_hash[:publisher]).to match_array(['Publisher 1'])
      expect(terms_hash[:subject]).to match_array(['Ireland','something else'])
      expect(terms_hash[:creation_date]).to include(:display => ['2000-2010'], :normal => ['20000101/20101231'])
      expect(terms_hash[:published_date]).to include(:display => ['2015'], :normal => ['20150101'])
      expect(terms_hash[:name_coverage]).to include(:display => ['Designer 1', 'Photographer 1'], :role => ['designer', 'photographer'], :tag => ['persname', 'corpname'])
      expect(terms_hash[:temporal_coverage]).to include(:normal => ['2005'], :datechar => ['coverage'], :display => ['c. 2005'])
      expect(terms_hash[:name_subject]).to match_array(['subject name'])
      expect(terms_hash[:persname_subject]).to match_array(['subject persname'])
      expect(terms_hash[:corpname_subject]).to match_array(['subject corpname'])
      expect(terms_hash[:geogname_subject]).to match_array(['subject geogname'])
      expect(terms_hash[:famname_subject]).to match_array(['subject famname'])
      expect(terms_hash[:geogname_coverage_access]).to include(:display => ['Dublin', 'name=Dublin; east=-6.266155; north=53.350140;', 'http://example.org/1234'], :type => ['', 'dcterms:Point', 'logainm'])
      expect(terms_hash[:type]).to match_array(['Collection'])
      expect(terms_hash[:related_material]).to match_array(['http://example.org/relmat'])
      expect(terms_hash[:alternative_form]).to match_array(['http://example.org/altform'])
      expect(terms_hash[:language]).to include(:langcode => ['en'], :text => ['English'])
    end

    it "should return a hash of attributes for form update (component)" do
      @component.attributes = @attributes_hash

      terms_hash = @component.get_hash_attributes

      expect(terms_hash[:title]).to match_array(['The test title'])
      expect(terms_hash[:creator]).to include(:display => ['Creator 1', 'Creator no role'], :role => ['institution', ''], :tag => ['persname', 'name'])
      expect(terms_hash[:contributor]).to match_array(['Contributor 1'])
      expect(terms_hash[:desc_scope_content]).to match_array(['This is a test description for the object.'])
      expect(terms_hash[:desc_abstract]).to match_array(['This is a test abstract for the object.'])
      expect(terms_hash[:desc_biog_hist]).to match_array(['This is a test biographical history for the object.'])
      expect(terms_hash[:rights]).to match_array(['This is a statement about the rights associated with this object'])
      expect(terms_hash[:publisher]).to match_array(['Publisher 1'])
      expect(terms_hash[:subject]).to match_array(['Ireland','something else'])
      expect(terms_hash[:creation_date]).to include(:display => ['2000-2010'], :normal => ['20000101/20101231'])
      expect(terms_hash[:published_date]).to include(:display => ['2015'], :normal => ['20150101'])
      expect(terms_hash[:name_coverage]).to include(:display => ['Designer 1', 'Photographer 1'], :role => ['designer', 'photographer'], :tag => ['persname', 'corpname'])
      expect(terms_hash[:temporal_coverage]).to include(:normal => ['2005'], :datechar => ['coverage'], :display => ['c. 2005'])
      expect(terms_hash[:name_subject]).to match_array(['subject name'])
      expect(terms_hash[:persname_subject]).to match_array(['subject persname'])
      expect(terms_hash[:corpname_subject]).to match_array(['subject corpname'])
      expect(terms_hash[:geogname_subject]).to match_array(['subject geogname'])
      expect(terms_hash[:famname_subject]).to match_array(['subject famname'])
      expect(terms_hash[:geogname_coverage_access]).to include(:type => ['', 'dcterms:Point', 'logainm'], :display => ['Dublin', 'name=Dublin; east=-6.266155; north=53.350140;', 'http://example.org/1234'])
      expect(terms_hash[:type]).to match_array(['Collection'])
      expect(terms_hash[:related_material]).to match_array(['http://example.org/relmat'])
      expect(terms_hash[:alternative_form]).to match_array(['http://example.org/altform'])
      expect(terms_hash[:language]).to include(:langcode => ['en'], :text => ['English'])
    end
  end
end