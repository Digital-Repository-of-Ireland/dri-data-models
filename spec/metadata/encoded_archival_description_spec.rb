require 'rsolr'

describe 'EncodedArchivalDescription descMetadata' do

  context 'create new ead xml' do
    before(:each) do
      @md_collection = DRI::Metadata::EncodedArchivalDescription.new
      @md_component = DRI::Metadata::EncodedArchivalDescriptionComponent.new
    end

    it 'should have an xml_template method returning desired xml' do
      # collection
      empty_xml = @md_collection.class.xml_template
      empty_xml.should be_a_kind_of(Nokogiri::XML::Document)
      expect(empty_xml.internal_subset).not_to be_nil
      expect(empty_xml.internal_subset.external_id).to eq('+//ISBN 1-931666-00-8//DTD ead.dtd (Encoded Archival Description (EAD) Version 2002)//EN')
      empty_xml.children.first.name.should eq('ead')

      # component
      empty_xml = @md_component.class.xml_template
      empty_xml.should be_a_kind_of(Nokogiri::XML::Document)
      empty_xml.children.first.name.should eq('c')
    end
  end

  context 'modify existing ead xml' do
    before(:each) do
      @md_collection = DRI::Metadata::EncodedArchivalDescription.new
      @md_component = DRI::Metadata::EncodedArchivalDescriptionComponent.new
    end

    it 'should update creator nodes' do
      c_hash = { display: ['A. Nolan'], tag: ['persname'], role: ['photographer'] }
      # Collection
      # Remove origination tag for creators
      @md_collection.ng_xml.search('//origination').each(&:remove)
      @md_collection.add_creator(c_hash)
      creators = @md_collection.ng_xml.search('//origination/persname')
      expect(creators.size).to eq 1

      # Component
      @md_component.ng_xml.search('//origination').each(&:remove)
      @md_component.add_creator(c_hash)
      creators = @md_component.ng_xml.search('//origination/persname')
      expect(creators.size).to eq 1

      c_hash = { display: ['B. Whitehall'], tag: ['name'], role: ['designer'] }
      # Collection
      @md_collection.add_creator(c_hash)
      creators = @md_collection.ng_xml.search('//origination/*[local-name() = "name" or local-name() = "persname"]')
      expect(creators.size).to eq 1
      expect(creators.first.name).to eq('name')
      expect(creators.first.content).to eq('B. Whitehall')

      # Component
      @md_component.add_creator(c_hash)
      creators = @md_component.ng_xml.search('//origination/*[local-name() = "name" or local-name() = "persname"]')
      expect(creators.size).to eq 1
      expect(creators.first.name).to eq('name')
      expect(creators.first.content).to eq('B. Whitehall')
    end

    it 'should update contributor nodes' do
      c_hash = ['A. Nolan']
      # Collection
      # Remove origination tag for contributors
      @md_collection.ng_xml.search('//origination').each(&:remove)
      @md_collection.add_contributor(c_hash)
      ctbs = @md_collection.ng_xml.search('//origination/persname[@role="contributor"]')
      expect(ctbs.size).to eq 1

      # Component
      @md_component.ng_xml.search('//origination').each(&:remove)
      @md_component.add_contributor(c_hash)
      ctbs = @md_component.ng_xml.search('//origination/persname[@role="contributor"]')
      expect(ctbs.size).to eq 1

      c_hash = ['B. Whitehall']
      # Collection
      @md_collection.add_contributor(c_hash)
      ctbs = @md_collection.ng_xml.search('//origination/*[@role="contributor"]')
      expect(ctbs.size).to eq 1
      expect(ctbs.first.content).to eq('B. Whitehall')

      # Component
      @md_component.add_contributor(c_hash)
      ctbs = @md_component.ng_xml.search('//origination/*[@role="contributor"]')
      expect(ctbs.size).to eq 1
      expect(ctbs.first.content).to eq('B. Whitehall')
    end

    it 'should update name_coverage nodes' do
      n_hash = {:display => ['A. Nolan'], :tag => ['persname'], :role => ['photographer']}
      # Collection
      # Remove origination tag for controlaccess
      @md_collection.ng_xml.search('//controlaccess').each(&:remove)
      @md_collection.add_name_coverage(n_hash)
      names = @md_collection.ng_xml.search('//controlaccess/persname')
      expect(names.size).to eq 1

      # Component
      @md_component.ng_xml.search('//controlaccess').each(&:remove)
      @md_component.add_name_coverage(n_hash)
      names = @md_component.ng_xml.search('//controlaccess/persname')
      expect(names.size).to eq 1

      n_hash = { display: ['B. Whitehall'], tag: ['corpname'], role: ['studio'] }
      # Collection
      @md_collection.add_name_coverage(n_hash)
      names = @md_collection.ng_xml.search('//controlaccess/*[local-name() = "corpname" or local-name() = "persname"]')
      expect(names.size).to eq 1
      expect(names.first.name).to eq('corpname')
      expect(names.first.content).to eq('B. Whitehall')

      # Component
      @md_component.add_name_coverage(n_hash)
      names = @md_component.ng_xml.search('//controlaccess/*[local-name() = "corpname" or local-name() = "persname"]')
      expect(names.size).to eq 1
      expect(names.first.name).to eq('corpname')
      expect(names.first.content).to eq('B. Whitehall')
    end

    it 'should update temporal_coverage nodes' do
      d_hash = { display: ['Jan 2015'], datechar: ['coverage'], normal: ['20150101'] }

      # Collection
      @md_collection.add_temporal_coverage(d_hash)
      dates = @md_collection.ng_xml.search('//unitdate[not(@datechar="creation") and not(@datechar="publication")]')
      expect(dates.size).to eq 1
      expect(dates.first['normal']).to eq('20150101')
      expect(dates.first.content).to eq('Jan 2015')

      # Component
      @md_component.add_temporal_coverage(d_hash)
      dates = @md_component.ng_xml.search('//unitdate[not(@datechar="creation") and not(@datechar="publication")]')
      expect(dates.size).to eq 1
      expect(dates.first['normal']).to eq('20150101')
      expect(dates.first.content).to eq('Jan 2015')
    end

    it 'should update related_material nodes' do
      rel_hash = ['http://example.org/relatedmaterial']

      # Collection
      @md_collection.add_related_material(rel_hash)
      rels = @md_collection.ng_xml.search('//relatedmaterial/extref')
      expect(rels.size).to eq 1
      expect(rels.first['href']).to eq('http://example.org/relatedmaterial')

      # Component
      @md_component.add_related_material(rel_hash)
      rels = @md_component.ng_xml.search('//relatedmaterial/extref')
      expect(rels.size).to eq 1
      expect(rels.first['href']).to eq('http://example.org/relatedmaterial')
    end

    it 'should update alternative_form nodes' do
      rel_hash = ['http://example.org/altformavail']

      # Collection
      @md_collection.add_alternative_form(rel_hash)
      rels = @md_collection.ng_xml.search('//altformavail/p/extref')
      expect(rels.size).to eq 1
      expect(rels.first['href']).to eq('http://example.org/altformavail')

      # Component
      @md_component.add_alternative_form(rel_hash)
      rels = @md_component.ng_xml.search('//altformavail/p/extref')
      expect(rels.size).to eq 1
      expect(rels.first['href']).to eq('http://example.org/altformavail')
    end

    it 'should update geographical coverage nodes' do
      geog_hash = { type: ['logainm'], display: ['http://example.org/1234'] }

      # Collection
      # Remove controlaccess tag for geographical coverage
      @md_collection.ng_xml.search('//controlaccess').each(&:remove)
      @md_collection.add_geogname_coverage_access(geog_hash)
      geogs = @md_collection.ng_xml.search('//controlaccess/geogname')
      expect(geogs.size).to eq 1

      # Component
      @md_component.ng_xml.search('//controlaccess').each(&:remove)
      @md_component.add_geogname_coverage_access(geog_hash)
      geogs = @md_component.ng_xml.search('////controlaccess/geogname')
      expect(geogs.size).to eq 1

      geog_hash = { type: ['dcterms:Point'], display: ['name=Dublin; east=-6.266155; north=53.350140;'] }
      # Collection
      @md_collection.add_geogname_coverage_access(geog_hash)
      geogs = @md_collection.ng_xml.search('//controlaccess/geogname')
      expect(geogs.size).to eq 1
      expect(geogs.first.content).to eq('name=Dublin; east=-6.266155; north=53.350140;')

      # Component
      @md_component.add_geogname_coverage_access(geog_hash)
      geogs = @md_component.ng_xml.search('//controlaccess/geogname')
      expect(geogs.size).to eq 1
      expect(geogs.first.content).to eq('name=Dublin; east=-6.266155; north=53.350140;')
    end

    it 'should update language nodes' do
      l_hash = { langcode: ['en'], text: ['English'] }
      # Collection
      # Remove origination tag for contributors
      @md_collection.ng_xml.search('//langmaterial').each(&:remove)
      @md_collection.add_language(l_hash)
      lang = @md_collection.ng_xml.search('//langmaterial/language')
      expect(lang.size).to eq 1

      # Component
      @md_component.ng_xml.search('//langmaterial').each(&:remove)
      @md_component.add_language(l_hash)
      lang = @md_component.ng_xml.search('//langmaterial/language')
      expect(lang.size).to eq 1

      l_hash = ['B. Whitehall']
      # Collection
      @md_collection.add_language(l_hash)
      lang = @md_collection.ng_xml.search('//langmaterial/language')
      expect(lang.size).to eq 1
      expect(lang.first.content).to eq('English')
      expect(lang.first['langcode']).to eq('en')

      # Component
      @md_component.add_language(l_hash)
      lang = @md_component.ng_xml.search('//langmaterial/language')
      expect(lang.size).to eq 1
      expect(lang.first.content).to eq('English')
      expect(lang.first['langcode']).to eq('en')
    end
  end

  context 'validation of DRI compulsory elements' do
    before(:each) do
      @collection_xml = fixture('ead/collections/ead_collection_dtd.xml')
      @series_xml = fixture('ead/components/component_series.xml')
      @file_xml = fixture('ead/components/component_file.xml')
      @item_xml = fixture('ead/components/component_item.xml')

      @ead_collection = DRI::EncodedArchivalDescription.new :collection
      @ead_collection.update_metadata(DRI::Metadata::EncodedArchivalDescription.from_xml(@collection_xml).to_xml, false)

      @ead_series = DRI::EncodedArchivalDescription.new :component
      @ead_series.update_metadata(DRI::Metadata::EncodedArchivalDescriptionComponent.from_xml(@series_xml).to_xml, false)

      @ead_file = DRI::EncodedArchivalDescription.new :component
      @ead_file.update_metadata(DRI::Metadata::EncodedArchivalDescriptionComponent.from_xml(@file_xml).to_xml, false)

      @ead_item = DRI::EncodedArchivalDescription.new :component
      @ead_item.update_metadata(DRI::Metadata::EncodedArchivalDescriptionComponent.from_xml(@item_xml).to_xml, false)
    end

    after(:each) do
      unless @ead_item.new_record?
        @ead_item.delete
      end
      unless @ead_file.new_record?
        @ead_file.delete
      end
      unless @ead_series.new_record?
        @ead_series.delete
      end
      unless @ead_collection.new_record?
        @ead_collection.delete
      end
    end

    it "should expose the EAD components\' identifiers" do
      expect(@ead_collection.identifier).to match_array(['IE/NIVAL KDW'])
      @ead_collection.country_code.should == 'IE'
      @ead_collection.repository_code.should == 'IE-DuNIV'
      @ead_collection.identifier_id.should == 'KDW'

      expect(@ead_series.identifier).to match_array(['KDW/RM'])
      @ead_series.country_code.should == 'IE'
      @ead_series.repository_code.should == 'IE-DuNIV'
      @ead_series.identifier_id.should == 'RM'

      expect(@ead_file.identifier).to match_array(['KDW/RM/02'])
      @ead_file.country_code.should == 'IE'
      @ead_file.repository_code.should == 'IE-DuNIV'
      @ead_file.identifier_id.should == '02'

      expect(@ead_item.identifier).to match_array(['KDW/RM/02/04'])
      @ead_item.country_code.should == 'IE'
      @ead_item.repository_code.should == 'IE-DuNIV'
      @ead_item.identifier_id.should == '04'
    end

    it 'should expose the level of the EAD component' do
      @ead_collection.ead_level.should == 'fonds'
      @ead_series.ead_level.should == 'series'
      @ead_file.ead_level.should == 'file'
      @ead_item.ead_level.should == 'item'
      @ead_series.ead_level = 'otherlevel'
      @ead_series.ead_level_other = 'subcollection'
      @ead_series.ead_level.should == 'otherlevel'
      @ead_series.ead_level_other.should == 'subcollection'
    end

    it 'should use the EAD component level to determine whether the component is a collection or not' do
      @ead_file.governed_items << @ead_item
      @ead_file.save
      @ead_series.governed_items << @ead_file
      @ead_series.save
      @ead_collection.governed_items << @ead_series
      @ead_collection.save

      @ead_collection.collection?.should == true
      @ead_collection.root_collection?.should == true

      @ead_series.collection?.should == true
      @ead_series.root_collection?.should == false

      @ead_file.collection?.should == true
      @ead_file.root_collection?.should == false

      @ead_item.collection?.should == false
      @ead_item.root_collection?.should == false
    end

    it 'should validate the presence of the title metadata field' do
      @ead_collection.should be_valid
      @ead_collection.title = ['']
      @ead_collection.should_not be_valid

      @ead_series.should be_valid
      @ead_series.title = ['']
      @ead_series.should_not be_valid

      @ead_file.should be_valid
      @ead_file.title = ['']
      @ead_file.should_not be_valid

      @ead_item.should be_valid
      @ead_item.title = ['']
      @ead_item.should_not be_valid
    end

    it 'should validate the presence of the description metadata fields' do
      @ead_collection.should be_valid
      @ead_collection.desc_scope_content = ['']
      @ead_collection.desc_abstract = ['']
      @ead_collection.desc_biog_hist = ['']
      @ead_collection.should_not be_valid
    end

    it 'should validate the presence of the rights metadata field' do
      @ead_collection.should be_valid
      @ead_collection.rights = ['']
      @ead_collection.should_not be_valid
      expect(@ead_collection.descMetadata.custom_validations).to have_key(:rights)
    end

    it 'should validate the presence of a date metadata field' do
      @ead_collection.should be_valid
      @ead_collection.creation_date = { display: [''], datechar: [''], normal: [''] }
      @ead_collection.temporal_coverage = { display: [''], datechar: [''], normal: [''] }
      @ead_collection.should_not be_valid
      expect(@ead_collection.descMetadata.custom_validations).to have_key(:date)
    end

    it 'should validate the presence of the creator metadata field' do
      @ead_collection.should be_valid
      @ead_collection.creator = { display: [''], role: [''], tag: [''] }
      @ead_collection.should_not be_valid
      expect(@ead_collection.descMetadata.custom_validations).to have_key(:creator)
    end

    it 'should validate the presence of the level attribute' do
      @ead_collection.should be_valid
      @ead_collection.ead_level = ''
      @ead_collection.should_not be_valid

      @ead_series.should be_valid
      @ead_series.ead_level = ''
      @ead_series.should_not be_valid

      @ead_file.should be_valid
      @ead_file.ead_level = ''
      @ead_file.should_not be_valid

      @ead_item.should be_valid
      @ead_item.ead_level = ''
      @ead_item.should_not be_valid

      # ead_level includes a value not present in the list of accepted values
      @ead_collection.ead_level = 'invalidlevel'
      @ead_collection.should_not be_valid
      expect(@ead_collection.descMetadata.custom_validations).to have_key(:ead_level)

      # ead_level is 'otherlevel' but the field ead_level_other is empty
      @ead_collection.ead_level = 'otherlevel'
      @ead_collection.ead_level_other = ''
      @ead_collection.should_not be_valid
      expect(@ead_collection.descMetadata.custom_validations).to have_key(:ead_level_other)

      @ead_collection.ead_level = 'otherlevel'
      @ead_collection.ead_level_other = 'subcollection'
      @ead_collection.should be_valid
      expect(@ead_collection.descMetadata.custom_validations).not_to have_key(:ead_level_other)

      # ead_level includes a value not present in the list of accepted values
      @ead_file.ead_level = 'invalidlevel'
      @ead_file.should_not be_valid
      expect(@ead_file.descMetadata.custom_validations).to have_key(:ead_level)

      # ead_level is 'otherlevel' but the field ead_level_other is empty
      @ead_file.ead_level = 'otherlevel'
      @ead_file.ead_level_other = ''
      @ead_file.should_not be_valid
      expect(@ead_file.descMetadata.custom_validations).to have_key(:ead_level_other)

      @ead_file.ead_level = 'otherlevel'
      @ead_file.ead_level_other = 'subcollection'
      @ead_file.should be_valid
      expect(@ead_file.descMetadata.custom_validations).not_to have_key(:ead_level_other)
    end

    it 'should validate the presence of an EAD identifier' do
      @ead_collection.should be_valid
      @ead_collection.identifier = ['']
      @ead_collection.should_not be_valid
      expect(@ead_collection.descMetadata.custom_validations).to have_key(:identifier)

      @ead_series.should be_valid
      @ead_series.identifier = ['']
      @ead_series.should_not be_valid
      expect(@ead_series.descMetadata.custom_validations).to have_key(:identifier)

      @ead_file.should be_valid
      @ead_file.identifier = ['']
      @ead_file.should_not be_valid
      expect(@ead_file.descMetadata.custom_validations).to have_key(:identifier)

      @ead_item.should be_valid
      @ead_item.identifier = ['']
      @ead_item.should_not be_valid
      expect(@ead_item.descMetadata.custom_validations).to have_key(:identifier)
    end

    it 'should validate the presence of the unitid countrycode attribute' do
      @ead_collection.should be_valid
      @ead_collection.country_code = ''
      @ead_collection.should_not be_valid
      expect(@ead_collection.descMetadata.custom_validations).to have_key(:country_code)

      @ead_series.should be_valid
      @ead_series.country_code = ''
      @ead_series.should_not be_valid
      expect(@ead_series.descMetadata.custom_validations).to have_key(:country_code)

      @ead_file.should be_valid
      @ead_file.country_code = ''
      @ead_file.should_not be_valid
      expect(@ead_file.descMetadata.custom_validations).to have_key(:country_code)

      @ead_item.should be_valid
      @ead_item.country_code = ''
      @ead_item.should_not be_valid
      expect(@ead_item.descMetadata.custom_validations).to have_key(:country_code)
    end

    it 'should validate the presence of the unitid repositorycode attribute' do
      @ead_collection.should be_valid
      @ead_collection.repository_code = ''
      @ead_collection.should_not be_valid
      expect(@ead_collection.descMetadata.custom_validations).to have_key(:repository_code)

      @ead_series.should be_valid
      @ead_series.repository_code = ''
      @ead_series.should_not be_valid
      expect(@ead_series.descMetadata.custom_validations).to have_key(:repository_code)

      @ead_file.should be_valid
      @ead_file.repository_code = ''
      @ead_file.should_not be_valid
      expect(@ead_file.descMetadata.custom_validations).to have_key(:repository_code)

      @ead_item.should be_valid
      @ead_item.repository_code = ''
      @ead_item.should_not be_valid
      expect(@ead_item.descMetadata.custom_validations).to have_key(:repository_code)
    end

    it 'should handle all variations of the EAD component node' do
      variations = ['c01', 'c02', 'c03', 'c04', 'c05', 'c06', 'c07', 'c08', 'c09', 'c10', 'c11', 'c12']
      variations.each do | curr_node_name |
        file_xml2 = fixture('ead/components/component_file.xml')
        curr_file = DRI::Metadata::EncodedArchivalDescriptionComponent.from_xml(file_xml2).to_xml
        curr_file = curr_file.gsub(/^<c/, '<'+curr_node_name)
        curr_file = curr_file.gsub(/c>$/, curr_node_name+'>')
        curr_batch = DRI::EncodedArchivalDescription.new :component
        curr_batch.update_metadata curr_file
        curr_batch.identifier.should == ['KDW/RM/02']
        curr_batch.ead_level.should == 'file'
      end
    end
  end # Context validation of DRI compulsory elements

  context 'terminology mappings' do
    before(:each) do
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
      @component.ead_level = 'file'

      @component_item = DRI::EncodedArchivalDescription.new(:component)
      @component_item.identifier = ['IE/NIVAL KDW']
      @component_item.identifier_id = 'KDW'
      @component_item.country_code = 'IE'
      @component_item.repository_code = 'IE-DuNIV'
      @component_item.ead_level = 'item'

      @attributes_hash = {
          title: ['The test title'],
          creator: { display: ['Creator 1'], role: ['institution'], tag: ['persname'] },
          contributor: ['Contributor 1'],
          publisher: ['Publisher 1'],
          desc_scope_content: ['This is a test description for the object.'],
          desc_abstract: ['This is a test abstract for the object.'],
          desc_biog_hist: ['This is a test biographical history for the object.'],
          rights: ['This is a statement about the rights associated with this object'],
          language: {:langcode => ['eng'], :text => ['English']},
          type: ['Collection'],
          published_date: { display: ['2015'], normal: ['20150101'] },
          creation_date: { display: ['2000-2010'], normal: ['20000101/20101231'] },
          name_coverage: { display: ['Designer 1', 'Photographer 1'], role: ['designer', 'photographer'], tag: ['persname', 'corpname'] },
          temporal_coverage: { normal: ['2005'], datechar: ['coverage'], display: ['c. 2005'] },
          geogname_coverage_access: { type: ['', 'dcterms:Point', 'logainm'], display: ['Dublin', 'name=Dublin; east=-6.266155; north=53.350140;', 'http://example.org/1234'] },
          subject: ['Ireland','something else'],
          name_subject: ['subject name'],
          persname_subject: ['subject persname'],
          corpname_subject: ['subject corpname'],
          geogname_subject: ['subject geogname'],
          famname_subject: ['subject famname'],
          related_material: ['http://example.org/relmat'],
          alternative_form: ['http://example.org/altform'],
          format: ['395 files']
      }
    end

    after(:each) do
      unless @component.new_record?
        @component.delete
      end
      unless @component_item.new_record?
        @component_item.delete
      end
      unless @collection.new_record?
        @collection.delete
      end
    end

    it 'should expose recommended metadata fields for indexing (ead collection)' do
      @collection.attributes = @attributes_hash

      solr_keys = ['title_tesim', 'title_sim', 'language_tesim', 'language_sim', 'contributor_sim', 'contributor_tesim',
                   'contributor_si', 'rights_sim', 'rights_tesim', 'type_sim', 'type_tesim', 'subject_tesim', 'subject_sim',
                   'creator_sim', 'creator_tesim', 'persname_subject_tesim', 'persname_subject_sim',
                   'geogname_subject_tesim', 'geogname_subject_sim', 'related_material_tesim', 'related_material_sim',
                   'alternative_form_tesim', 'alternative_form_sim', 'title_sorted_ssi', 'person_sim', 'person_tesim',
                   'all_metadata_tesim', 'name_coverage_tesim', 'name_coverage_sim', 'geographical_coverage_tesim',
                   'geographical_coverage_sim', 'creation_date_tesim', 'temporal_coverage_tesim', 'temporal_coverage_sim',
                   'creation_date_idx_tesim', 'published_date_tesim', 'cdateRange', 'pdateRange', 'sdateRange', 'geospatial',
                   'placename_field_tesim', 'placename_field_sim', 'geojson_ssim', 'description_sim', 'description_tesim',
                   'publisher_tesim', 'corpname_subject_sim', 'corpname_subject_tesim', 'famname_subject_sim',
                   'famname_subject_tesim', 'name_subject_sim', 'name_subject_tesim', 'ead_level_sim', 'ead_level_tesim',
                   'format_sim', 'format_tesim', 'resource_type_sim', 'resource_type_tesim']

      expect(@collection.descMetadata.to_solr.keys).to match_array(solr_keys)
      solr_doc = @collection.descMetadata.to_solr
      expect(solr_doc.keys).to match_array(solr_keys)

      title = solr_doc[ActiveFedora.index_field_mapper.solr_name('title', :stored_searchable)]
      description = solr_doc[ActiveFedora.index_field_mapper.solr_name('description', :stored_searchable)]
      creator = solr_doc[ActiveFedora.index_field_mapper.solr_name('creator', :stored_searchable)]
      contributor = solr_doc[ActiveFedora.index_field_mapper.solr_name('contributor', :stored_searchable)]
      publisher = solr_doc[ActiveFedora.index_field_mapper.solr_name('publisher', :stored_searchable)]
      rights = solr_doc[ActiveFedora.index_field_mapper.solr_name('rights', :stored_searchable)]
      language = solr_doc[ActiveFedora.index_field_mapper.solr_name('language', :stored_searchable)]

      subject = solr_doc[ActiveFedora.index_field_mapper.solr_name('subject', :stored_searchable)]
      corpname_subject = solr_doc[ActiveFedora.index_field_mapper.solr_name('corpname_subject', :stored_searchable)]
      name_subject = solr_doc[ActiveFedora.index_field_mapper.solr_name('name_subject', :stored_searchable)]
      famname_subject = solr_doc[ActiveFedora.index_field_mapper.solr_name('famname_subject', :stored_searchable)]
      persname_subject = solr_doc[ActiveFedora.index_field_mapper.solr_name('persname_subject', :stored_searchable)]
      geogname_subject = solr_doc[ActiveFedora.index_field_mapper.solr_name('geogname_subject', :stored_searchable)]
      name_coverage = solr_doc[ActiveFedora.index_field_mapper.solr_name('name_coverage', :stored_searchable)]

      creation_date = solr_doc[ActiveFedora.index_field_mapper.solr_name('creation_date', :stored_searchable)]
      creation_date_idx = solr_doc[ActiveFedora.index_field_mapper.solr_name('creation_date_idx', :stored_searchable)]
      cdate_range = solr_doc[DRI::Metadata::Transformations::CREATION_DATE_RANGE_SOLR_FIELD]
      published_date = solr_doc[ActiveFedora.index_field_mapper.solr_name('published_date', :stored_searchable)]
      pdate_range = solr_doc[DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_SOLR_FIELD]
      temporal_coverage = solr_doc[ActiveFedora.index_field_mapper.solr_name('temporal_coverage', :stored_searchable)]
      sdate_range = solr_doc[DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_SOLR_FIELD]

      geographical_coverage = solr_doc[ActiveFedora.index_field_mapper.solr_name('geographical_coverage', :stored_searchable)]
      place_name = solr_doc[ActiveFedora.index_field_mapper.solr_name(DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD, :stored_searchable)]
      geo_spatial = solr_doc[DRI::Metadata::Transformations::GEOSPATIAL_SOLR_FIELD]
      geo_json = solr_doc[DRI::Metadata::Transformations::GEOJSON_SOLR_FIELD]

      alternative_form = solr_doc[ActiveFedora.index_field_mapper.solr_name('alternative_form', :stored_searchable)]
      related_material = solr_doc[ActiveFedora.index_field_mapper.solr_name('related_material', :stored_searchable)]
      format = solr_doc[ActiveFedora.index_field_mapper.solr_name('format', :stored_searchable)]

      expect(title).to match_array(['The test title'])
      expect(description).to match_array(['This is a test description for the object.'])
      expect(creator).to match_array(['Creator 1 (institution)'])
      expect(contributor).to match_array(['Contributor 1'])
      expect(publisher).to match_array(['Publisher 1'])
      expect(rights).to match_array(['This is a statement about the rights associated with this object'])
      expect(language).to match_array(['English'])
      expect(subject).to match_array(['Ireland', 'something else', 'subject corpname', 'subject famname', 'subject geogname', 'subject name', 'subject persname'])
      expect(name_coverage).to match_array( ["Designer 1 (designer)", "Photographer 1 (photographer)"])
      expect(corpname_subject).to match_array(['subject corpname'])
      expect(name_subject).to match_array(['subject name'])
      expect(famname_subject).to match_array(['subject famname'])
      expect(persname_subject).to match_array(['subject persname'])
      expect(geogname_subject).to match_array(['subject geogname'])
      expect(creation_date).to match_array(['name=2000-2010; start=20000101; end=20101231;'])
      expect(cdate_range).to match_array(['2000 2010'])
      expect(creation_date_idx).to match_array(['20000101/20101231'])
      expect(published_date).to match_array(['name=2015; start=20150101;'])
      expect(pdate_range).to match_array(['2015 2015'])
      expect(temporal_coverage).to match_array(['name=c. 2005; start=2005;'])
      expect(sdate_range).to match_array(['2005 2005'])
      expect(geographical_coverage).to match_array(['Dublin', 'name=Dublin; east=-6.266155; north=53.350140;', 'http://example.org/1234'])
      expect(place_name).to match_array(['Dublin'])
      expect(geo_spatial).to match_array(['-6.266155 53.350140'])
      expect(geo_json).to match_array(["{\"type\":\"Feature\",\"geometry\":{\"type\":\"Point\",\"coordinates\":[-6.266155,53.35014]},\"properties\":{\"placename\":\"Dublin\"}}"])
      expect(related_material).to match_array(['http://example.org/relmat'])
      expect(alternative_form).to match_array(['http://example.org/altform'])
      expect(format).to match_array(['395 files'])
    end

    it 'should expose recommended metadata fields for indexing (ead component)' do
      @component.attributes = @attributes_hash

      solr_keys = ['title_tesim', 'title_sim', 'language_tesim', 'language_sim', 'contributor_sim', 'contributor_tesim',
                   'contributor_si', 'rights_sim', 'rights_tesim', 'type_sim', 'type_tesim', 'subject_tesim', 'subject_sim',
                   'creator_sim', 'creator_tesim', 'persname_subject_tesim', 'persname_subject_sim',
                   'geogname_subject_tesim', 'geogname_subject_sim', 'related_material_tesim', 'related_material_sim',
                   'alternative_form_tesim', 'alternative_form_sim', 'title_sorted_ssi', 'person_sim', 'person_tesim',
                   'all_metadata_tesim', 'name_coverage_tesim', 'name_coverage_sim', 'geographical_coverage_tesim',
                   'geographical_coverage_sim', 'creation_date_tesim', 'temporal_coverage_tesim', 'temporal_coverage_sim',
                   'creation_date_idx_tesim', 'published_date_tesim', 'cdateRange', 'pdateRange', 'sdateRange', 'geospatial',
                   'placename_field_tesim', 'placename_field_sim', 'geojson_ssim', 'description_sim', 'description_tesim',
                   'publisher_tesim', 'corpname_subject_sim', 'corpname_subject_tesim', 'famname_subject_sim',
                   'famname_subject_tesim', 'name_subject_sim', 'name_subject_tesim', 'ead_level_sim', 'ead_level_tesim',
                   'format_sim', 'format_tesim', 'resource_type_sim', 'resource_type_tesim']

      expect(@component.descMetadata.to_solr.keys).to match_array(solr_keys)
      solr_doc = @component.descMetadata.to_solr
      expect(solr_doc.keys).to match_array(solr_keys)

      title = solr_doc[ActiveFedora.index_field_mapper.solr_name('title', :stored_searchable)]
      description = solr_doc[ActiveFedora.index_field_mapper.solr_name('description', :stored_searchable)]
      creator = solr_doc[ActiveFedora.index_field_mapper.solr_name('creator', :stored_searchable)]
      contributor = solr_doc[ActiveFedora.index_field_mapper.solr_name('contributor', :stored_searchable)]
      publisher = solr_doc[ActiveFedora.index_field_mapper.solr_name('publisher', :stored_searchable)]
      rights = solr_doc[ActiveFedora.index_field_mapper.solr_name('rights', :stored_searchable)]
      language = solr_doc[ActiveFedora.index_field_mapper.solr_name('language', :stored_searchable)]

      subject = solr_doc[ActiveFedora.index_field_mapper.solr_name('subject', :stored_searchable)]
      corpname_subject = solr_doc[ActiveFedora.index_field_mapper.solr_name('corpname_subject', :stored_searchable)]
      name_subject = solr_doc[ActiveFedora.index_field_mapper.solr_name('name_subject', :stored_searchable)]
      famname_subject = solr_doc[ActiveFedora.index_field_mapper.solr_name('famname_subject', :stored_searchable)]
      persname_subject = solr_doc[ActiveFedora.index_field_mapper.solr_name('persname_subject', :stored_searchable)]
      geogname_subject = solr_doc[ActiveFedora.index_field_mapper.solr_name('geogname_subject', :stored_searchable)]
      name_coverage = solr_doc[ActiveFedora.index_field_mapper.solr_name('name_coverage', :stored_searchable)]

      creation_date = solr_doc[ActiveFedora.index_field_mapper.solr_name('creation_date', :stored_searchable)]
      creation_date_idx = solr_doc[ActiveFedora.index_field_mapper.solr_name('creation_date_idx', :stored_searchable)]
      cdate_range = solr_doc[DRI::Metadata::Transformations::CREATION_DATE_RANGE_SOLR_FIELD]
      published_date = solr_doc[ActiveFedora.index_field_mapper.solr_name('published_date', :stored_searchable)]
      pdate_range = solr_doc[DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_SOLR_FIELD]
      temporal_coverage = solr_doc[ActiveFedora.index_field_mapper.solr_name('temporal_coverage', :stored_searchable)]
      sdate_range = solr_doc[DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_SOLR_FIELD]

      geographical_coverage = solr_doc[ActiveFedora.index_field_mapper.solr_name('geographical_coverage', :stored_searchable)]
      place_name = solr_doc[ActiveFedora.index_field_mapper.solr_name(DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD, :stored_searchable)]
      geo_spatial = solr_doc[DRI::Metadata::Transformations::GEOSPATIAL_SOLR_FIELD]
      geo_json = solr_doc[DRI::Metadata::Transformations::GEOJSON_SOLR_FIELD]

      alternative_form = solr_doc[ActiveFedora.index_field_mapper.solr_name('alternative_form', :stored_searchable)]
      related_material = solr_doc[ActiveFedora.index_field_mapper.solr_name('related_material', :stored_searchable)]
      format = solr_doc[ActiveFedora.index_field_mapper.solr_name('format', :stored_searchable)]

      expect(title).to match_array(['The test title'])
      expect(description).to match_array(['This is a test description for the object.'])
      expect(creator).to match_array(['Creator 1 (institution)'])
      expect(contributor).to match_array(['Contributor 1'])
      expect(publisher).to match_array(['Publisher 1'])
      expect(rights).to match_array(['This is a statement about the rights associated with this object'])
      expect(language).to match_array(['English'])
      expect(subject).to match_array(['Ireland', 'something else', 'subject corpname', 'subject famname', 'subject geogname', 'subject name', 'subject persname'])
      expect(name_coverage).to match_array( ["Designer 1 (designer)", "Photographer 1 (photographer)"])
      expect(corpname_subject).to match_array(['subject corpname'])
      expect(name_subject).to match_array(['subject name'])
      expect(famname_subject).to match_array(['subject famname'])
      expect(persname_subject).to match_array(['subject persname'])
      expect(geogname_subject).to match_array(['subject geogname'])
      expect(creation_date).to match_array(['name=2000-2010; start=20000101; end=20101231;'])
      expect(cdate_range).to match_array(['2000 2010'])
      expect(creation_date_idx).to match_array(['20000101/20101231'])
      expect(published_date).to match_array(['name=2015; start=20150101;'])
      expect(pdate_range).to match_array(['2015 2015'])
      expect(temporal_coverage).to match_array(['name=c. 2005; start=2005;'])
      expect(sdate_range).to match_array(['2005 2005'])
      expect(geographical_coverage).to match_array(['Dublin', 'name=Dublin; east=-6.266155; north=53.350140;', 'http://example.org/1234'])
      expect(place_name).to match_array(['Dublin'])
      expect(geo_spatial).to match_array(['-6.266155 53.350140'])
      expect(geo_json).to match_array(["{\"type\":\"Feature\",\"geometry\":{\"type\":\"Point\",\"coordinates\":[-6.266155,53.35014]},\"properties\":{\"placename\":\"Dublin\"}}"])
      expect(related_material).to match_array(['http://example.org/relmat'])
      expect(alternative_form).to match_array(['http://example.org/altform'])
      expect(format).to match_array(['395 files'])
    end

    it 'should index display dates as dcterms:Point (ead collection and component)' do
      @collection.attributes = @attributes_hash
      @component.attributes = @attributes_hash

      expect(@collection.creation_date).to match_array(['2000-2010'])
      expect(@collection.creation_date_idx).to match_array(['20000101/20101231'])

      solr_doc = @collection.descMetadata.to_solr
      creation_date = solr_doc[ActiveFedora.index_field_mapper.solr_name('creation_date', :stored_searchable)]
      expect(creation_date).to match_array(['name=2000-2010; start=20000101; end=20101231;'])
      expect(solr_doc['cdateRange']).to match_array(['2000 2010'])

      expect(@component.creation_date).to match_array(['2000-2010'])
      expect(@component.creation_date_idx).to match_array(['20000101/20101231'])
      expect(@component.descMetadata.creation_date_for_index).to match_array(['name=2000-2010; start=20000101; end=20101231;'])

      @component.creation_date = {:display => ['May 2015'], :normal => ['']}
      expect(@component.creation_date).to match_array(['May 2015'])
      expect(@component.creation_date_idx).to match_array([])
      expect(@component.descMetadata.creation_date_for_index).to match_array(['name=May 2015;'])
    end

    it 'should not index incomplete temporal information (collection)' do
      @collection.published_date = {:display => ['2015'], :normal => ['']}
      @collection.creation_date = {:display => ['2000-2010'], :normal => ['']}
      @collection.temporal_coverage = {:normal => [''], :datechar => ['coverage'], :display => ['c. 2005']}

      solr_doc = @collection.descMetadata.to_solr

      # creation date
      creation_date = solr_doc[ActiveFedora.index_field_mapper.solr_name('creation_date', :stored_searchable)]
      creation_date_idx = solr_doc[ActiveFedora.index_field_mapper.solr_name('creation_date_idx', :stored_searchable)]
      cdate_range = solr_doc[DRI::Metadata::Transformations::CREATION_DATE_RANGE_SOLR_FIELD]

      # published date
      published_date = solr_doc[ActiveFedora.index_field_mapper.solr_name('published_date', :stored_searchable)]
      pdate_range = solr_doc[DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_SOLR_FIELD]

      # temporal coverage
      temporal_coverage = solr_doc[ActiveFedora.index_field_mapper.solr_name('temporal_coverage', :stored_searchable)]
      sdate_range = solr_doc[DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_SOLR_FIELD]

      expect(creation_date).to match_array(['name=2000-2010;'])
      expect(cdate_range).to be_nil
      expect(creation_date_idx).to match_array([])
      expect(published_date).to match_array(['name=2015;'])
      expect(pdate_range).to be_nil
      expect(temporal_coverage).to match_array(['name=c. 2005;'])
      expect(sdate_range).to be_nil

    end

    it 'should not index incomplete temporal information (component)' do
      @component.published_date = {:display => ['2015'], :normal => ['']}
      @component.creation_date = {:display => ['2000-2010'], :normal => ['']}
      @component.temporal_coverage = {:normal => [''], :datechar => ['coverage'], :display => ['c. 2005']}

      solr_doc = @component.descMetadata.to_solr

      # creation date
      creation_date = solr_doc[ActiveFedora.index_field_mapper.solr_name('creation_date', :stored_searchable)]
      creation_date_idx = solr_doc[ActiveFedora.index_field_mapper.solr_name('creation_date_idx', :stored_searchable)]
      cdate_range = solr_doc[DRI::Metadata::Transformations::CREATION_DATE_RANGE_SOLR_FIELD]

      # published date
      published_date = solr_doc[ActiveFedora.index_field_mapper.solr_name('published_date', :stored_searchable)]
      pdate_range = solr_doc[DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_SOLR_FIELD]

      # temporal coverage
      temporal_coverage = solr_doc[ActiveFedora.index_field_mapper.solr_name('temporal_coverage', :stored_searchable)]
      sdate_range = solr_doc[DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_SOLR_FIELD]

      expect(creation_date).to match_array(['name=2000-2010;'])
      expect(cdate_range).to be_nil
      expect(creation_date_idx).to match_array([])
      expect(published_date).to match_array(['name=2015;'])
      expect(pdate_range).to be_nil
      expect(temporal_coverage).to match_array(['name=c. 2005;'])
      expect(sdate_range).to be_nil
    end

    it 'should not index incomplete geospatial information (collection)' do
      # name=Republic of Ireland; northlimit=55.3826405; eastlimit=-6.0007535; southlimit=51.4201065; westlimit=-10.577897;
      @collection.geogname_coverage_access=({:type => ['dcterms:Box'], :display => ['name=Republic of Ireland; northlimit=55.3826405;']})

      solr_doc = @collection.descMetadata.to_solr

      geographical_coverage = solr_doc[ActiveFedora.index_field_mapper.solr_name('geographical_coverage', :stored_searchable)]
      place_name = solr_doc[ActiveFedora.index_field_mapper.solr_name(DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD, :stored_searchable)]
      geo_spatial = solr_doc[DRI::Metadata::Transformations::GEOSPATIAL_SOLR_FIELD]
      geo_json = solr_doc[DRI::Metadata::Transformations::GEOJSON_SOLR_FIELD]

      expect(geographical_coverage).to match_array(['name=Republic of Ireland; northlimit=55.3826405;'])
      expect(place_name).to be_nil
      expect(geo_spatial).to be_nil
      expect(geo_json).to be_nil

      @collection.geogname_coverage_access=({:type => ['dcterms:Box'], :display => ['name=Republic of Ireland; northlimit=55.3826405; eastlimit=-6.0007535; southlimit=51.4201065; westlimit=-10.577897;']})

      solr_doc = @collection.descMetadata.to_solr

      geographical_coverage = solr_doc[ActiveFedora.index_field_mapper.solr_name('geographical_coverage', :stored_searchable)]
      place_name = solr_doc[ActiveFedora.index_field_mapper.solr_name(DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD, :stored_searchable)]
      geo_spatial = solr_doc[DRI::Metadata::Transformations::GEOSPATIAL_SOLR_FIELD]
      geo_json = solr_doc[DRI::Metadata::Transformations::GEOJSON_SOLR_FIELD]

      expect(geographical_coverage).to match_array(['name=Republic of Ireland; northlimit=55.3826405; eastlimit=-6.0007535; southlimit=51.4201065; westlimit=-10.577897;'])
      expect(place_name).to match_array(['Republic of Ireland'])
      expect(geo_spatial).to match_array(['-10.577897 51.4201065 -6.0007535 55.3826405'])
      expect(geo_json).to match_array(["{\"type\":\"Feature\",\"geometry\":{\"type\":\"Polygon\",\"coordinates\":[[[-10.577897,51.4201065],[-6.0007535,51.4201065],[-6.0007535,55.3826405],[-10.577897,55.3826405],[-10.577897,51.4201065]]]},\"properties\":{\"placename\":\"Republic of Ireland\"},\"bbox\":[-10.577897,51.4201065,-6.0007535,55.3826405]}"])
    end

    it 'should not index incomplete geospatial information (component)' do
      # name=Republic of Ireland; northlimit=55.3826405; eastlimit=-6.0007535; southlimit=51.4201065; westlimit=-10.577897;
      @component.geogname_coverage_access=({:type => ['dcterms:Box'], :display => ['name=Republic of Ireland; northlimit=55.3826405;']})

      solr_doc = @component.descMetadata.to_solr

      geographical_coverage = solr_doc[ActiveFedora.index_field_mapper.solr_name('geographical_coverage', :stored_searchable)]
      place_name = solr_doc[ActiveFedora.index_field_mapper.solr_name(DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD, :stored_searchable)]
      geo_spatial = solr_doc[DRI::Metadata::Transformations::GEOSPATIAL_SOLR_FIELD]
      geo_json = solr_doc[DRI::Metadata::Transformations::GEOJSON_SOLR_FIELD]

      expect(geographical_coverage).to match_array(['name=Republic of Ireland; northlimit=55.3826405;'])
      expect(place_name).to be_nil
      expect(geo_spatial).to be_nil
      expect(geo_json).to be_nil

      @component.geogname_coverage_access=({:type => ['dcterms:Box'], :display => ['name=Republic of Ireland; northlimit=55.3826405; eastlimit=-6.0007535; southlimit=51.4201065; westlimit=-10.577897;']})

      solr_doc = @component.descMetadata.to_solr

      geographical_coverage = solr_doc[ActiveFedora.index_field_mapper.solr_name('geographical_coverage', :stored_searchable)]
      place_name = solr_doc[ActiveFedora.index_field_mapper.solr_name(DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD, :stored_searchable)]
      geo_spatial = solr_doc[DRI::Metadata::Transformations::GEOSPATIAL_SOLR_FIELD]
      geo_json = solr_doc[DRI::Metadata::Transformations::GEOJSON_SOLR_FIELD]

      expect(geographical_coverage).to match_array(['name=Republic of Ireland; northlimit=55.3826405; eastlimit=-6.0007535; southlimit=51.4201065; westlimit=-10.577897;'])
      expect(place_name).to match_array(['Republic of Ireland'])
      expect(geo_spatial).to match_array(['-10.577897 51.4201065 -6.0007535 55.3826405'])
      expect(geo_json).to match_array(["{\"type\":\"Feature\",\"geometry\":{\"type\":\"Polygon\",\"coordinates\":[[[-10.577897,51.4201065],[-6.0007535,51.4201065],[-6.0007535,55.3826405],[-10.577897,55.3826405],[-10.577897,51.4201065]]]},\"properties\":{\"placename\":\"Republic of Ireland\"},\"bbox\":[-10.577897,51.4201065,-6.0007535,55.3826405]}"])
    end
  end
end
