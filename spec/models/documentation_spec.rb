describe 'Documentation' do
  before(:each) do
    @doc = DRI::Documentation.new
    @dc_obj = DRI::QualifiedDublinCore.new

    @attributes_hash = { type: ['Documentation'],
                         title: ['Documentation object'],
                         rights: ['This is a statement about the rights associated with this object'],
                         role_aut: ['AMG'],
                         language: ['en'],
                         description: ['This is a documentation object.'],
                         published_date: ['1916-04-01'],
                         creation_date: ['1916-01-01'],
                         source: ['Unknown'],
                         geographical_coverage: ['name=Dublin; north=53.3478; east=-6.25972;', 'name=Ireland; northlimit=55.39; eastlimit=-5.24; southlimit=51.47; westlimit=-10.44;'],
                         temporal_coverage: ['name=1900s; start=19000101; end=19991231'],
                         subject: ['Ireland'],
                         geocode_box: ['name=Ireland; northlimit=55.39; eastlimit=-5.24; southlimit=51.47; westlimit=-10.44;'],
                         geocode_point: ['name=Dublin; north=53.3478; east=-6.25972;']
    }
  end

  after(:each) do
    @doc.delete unless @doc.new_record?
    @dc_obj.delete unless @dc_obj.new_record?
  end

  it 'should have asserted the content model' do
    expect(@doc.has_model.to_a).to match_array(['DRI::Documentation', 'DRI::DigitalObject'])
  end

  it 'should find an existing object' do
    @doc.update_attributes(@attributes_hash)
    @doc.documentation_for = @dc_obj
    @doc.save
    @doc2 = DRI::Documentation.find_or_create(@doc.alternate_id)
    expect(@doc2.new_record?).to eq false
  end

  it 'should create a new object if there isnt an existing object for a given id' do
    @doc.update_attributes(@attributes_hash)
    @doc.save
    @doc2 = DRI::Documentation.find_or_create('fake-doc-id')
    expect(@doc2.new_record?).to eq true
    @doc2.delete
  end

  it 'should retrieve an existing object' do
    @dc_obj.update_attributes(@attributes_hash)
    @dc_obj.save

    @doc.update_attributes(@attributes_hash)
    @doc.documentation_for = @dc_obj
    @doc.save
    coverage = @attributes_hash[:geographical_coverage] << @attributes_hash[:geocode_box] << @attributes_hash[:geocode_point]

    @doc.new_record?.should == false
    @doc2 = DRI::Documentation.find_or_create(@doc.alternate_id)
    @doc2.title.should == @attributes_hash[:title]
    @doc2.rights.should == @attributes_hash[:rights]
    @doc2.description.should == @attributes_hash[:description]
    @doc2.published_date.should == @attributes_hash[:published_date]
    @doc2.creation_date.should == @attributes_hash[:creation_date]
    @doc2.language.should == @attributes_hash[:language]
    @doc2.role_aut.should == @attributes_hash[:role_aut]
    @doc2.subject.should == @attributes_hash[:subject]
    @doc2.source.should == @attributes_hash[:source]
    @doc2.geographical_coverage.should == coverage.flatten
    @doc2.temporal_coverage.should == @attributes_hash[:temporal_coverage]
    @doc2.type.should == @attributes_hash[:type]

    @doc2.should be_valid
  end

  it 'should assert isDescriptionOf predicate if associated with an object' do
    profile_key = ActiveFedora.index_field_mapper.solr_name('object_profile', :displayable)
    @doc.attributes = @attributes_hash
    @doc.save

    @dc_obj.attributes = @attributes_hash
    @dc_obj.documentation_objects << @doc
    @dc_obj.save

    @doc.reload
    expect(@doc.to_solr[ActiveFedora.index_field_mapper.solr_name('isDescriptionOf', :stored_searchable, type: :symbol)]).to eq [@dc_obj.alternate_id]

  end

  it 'should have the specified datastreams' do
    # Check for descMetadata datastream with MODS in it
    @doc.attached_files.keys.should include('descMetadata')
    @doc.descMetadata.should be_kind_of DRI::Metadata::QualifiedDublinCore
  end

  it 'should not be valid with no metadata' do
    @doc.should_not be_valid
  end

  it 'the status property should be set as "draft" when a new Audio object is created' do
    @doc = DRI::Documentation.new
    @doc.status.should == 'draft'
  end

  it 'should update the role attributes' do
    new_roles = { 'type' => ['role_hst', 'role_pro', 'role_aut'],
                  'name' => ['new host', 'new producer', 'new author'] }

    @doc.update_attributes(@attributes_hash)
    expect(@doc.role_aut).to match_array(@attributes_hash[:role_aut])

    @doc.roles= new_roles
    expect(@doc.role_hst).to match_array(['new host'])
    expect(@doc.role_pro).to match_array(['new producer'])
    expect(@doc.role_aut).to match_array(['new author'])
  end

  it 'should index geographical information' do
    hash = { temporal_coverage: ['name=1900s; start=19000101; end=19991231'],
             subject: ['Ireland'],
             geocode_box: ['name=Ireland; northlimit=55.39; eastlimit=-5.24; southlimit=51.47; westlimit=-10.44;'],
             geocode_point: ['name=Dublin; north=53.3478; east=-6.25972;'] }
    @obj = DRI::Documentation.new
    @obj.update_attributes(hash)

    expect(@obj.geocode_point).to match_array(['name=Dublin; north=53.3478; east=-6.25972;'])
    expect(@obj.geocode_box).to match_array(['name=Ireland; northlimit=55.39; eastlimit=-5.24; southlimit=51.47; westlimit=-10.44;'])

    solr_doc = @obj.descMetadata.to_solr
    keys = [DRI::Metadata::Transformations::GEOSPATIAL_SOLR_FIELD,
            ActiveFedora.index_field_mapper.solr_name(DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD, :stored_searchable),
            ActiveFedora.index_field_mapper.solr_name(DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD, :facetable, type: :text),
            ActiveFedora.index_field_mapper.solr_name('geojson', :stored_searchable, type: :symbol)]
    expect(solr_doc).to include(*keys)

    geojson_value = ["{\"type\":\"Feature\",\"geometry\":{\"type\":\"Point\",\"coordinates\":[-6.25972,53.3478]},\"properties\":{\"placename\":\"Dublin\",\"nameEN\":\"Dublin\"}}", "{\"type\":\"Feature\",\"geometry\":{\"type\":\"Polygon\",\"coordinates\":[[[-10.44,51.47],[-5.24,51.47],[-5.24,55.39],[-10.44,55.39],[-10.44,51.47]]]},\"properties\":{\"placename\":\"Ireland\",\"nameEN\":\"Ireland\"},\"bbox\":[-10.44,51.47,-5.24,55.39]}"]
    geo_json_key = ActiveFedora.index_field_mapper.solr_name('geojson', :stored_searchable, type: :symbol)
    expect(solr_doc[geo_json_key]).to match_array(geojson_value)

    geospatial_value = ['-6.25972 53.3478', 'ENVELOPE(-10.44, -5.24, 55.39, 51.47)']
    geospatial_key = DRI::Metadata::Transformations::GEOSPATIAL_SOLR_FIELD
    expect(solr_doc[geospatial_key]).to match_array(geospatial_value)

    placename_value = ['Dublin', 'Ireland']
    placename_key = ActiveFedora.index_field_mapper.solr_name(DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD, :stored_searchable)
    expect(solr_doc[placename_key]).to match_array(placename_value)
  end

  it 'should index temporal information' do
    hash = { temporal_coverage: ['name=1900s; start=19000101; end=19991231',
                                 'name=2015; start=2015;'] }
    @obj = DRI::Documentation.new
    @obj.update_attributes(hash)

    expect(@obj.temporal_coverage).to match_array(['name=1900s; start=19000101; end=19991231', 'name=2015; start=2015;'])

    solr_doc = @obj.descMetadata.to_solr
    keys = [ActiveFedora.index_field_mapper.solr_name('temporal_coverage', :stored_searchable),
            DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_SOLR_FIELD]
    expect(solr_doc).to include(*keys)
    expect(solr_doc[keys.last]).to include('[19000101 TO 19991231]', '2015')
  end
end
