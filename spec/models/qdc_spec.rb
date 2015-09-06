require 'spec_helper'

describe 'Batch' do
  
  before(:each) do
    # This gives you a test article object that can be used in any of the tests
    @audio = DRI::QualifiedDublinCore.new
    @audio.type = ["Sound"]

    @attributes_hash = {
      "title" => ["The Audio Title"],
      "rights" => ["This is a statement about the rights associated with this object"],
      "role_hst" => ["Collins, Michael"],
      "role_pro" => ["Collins, Michael"],
      "role_aut" => ["Valera, Eamon, de", "Connolly, James"],
      "language" => ["ga"],
      "description" => ["Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."],
      "published_date" => ["1916-04-01"],
      "creation_date" => ["1916-01-01"],
      "source" => ["CD nnn nuig"],
      "geographical_coverage" => ["Dublin"],
      "temporal_coverage" => ["1900s"],
      "subject" => ["Ireland","something else"]
    }

  end

  it "should load from xml" do
    @dc = fixture("audios/dublin_core_audio_sample1.xml")
    @ds = DRI::Metadata::QualifiedDublinCore.from_xml(@dc)
    audio2 = DRI::QualifiedDublinCore.new
    audio2.update_metadata @ds.to_xml
    audio2.descMetadata.content_changed?.should == true
    audio2.should be_valid
    audio2.creator.should == ["Gallagher, Damien"]
  end

  #it "should load from Fedora" do
  #  @audio.update_attributes( @attributes_hash )
  #  @audio.save
  #  @audio.new_record?.should == false
  #  @audio3 = Batch.find(@audio.pid)
  #  @audio3.title.should == @attributes_hash["title"]
  #  @audio3.rights.should == @attributes_hash["rights"]
  #  @audio3.description.should == @attributes_hash["description"]
  #  @audio3.published_date.should == @attributes_hash["published_date"]
  #  @audio3.creation_date.should == @attributes_hash["creation_date"]
  #  @audio3.language.should == @attributes_hash["language"]
  #  @audio3.role_pro.should == @attributes_hash["role_hst"]
  #  @audio3.role_hst.should == @attributes_hash["role_pro"]
  #  @audio3.role_aut.should == @attributes_hash["role_aut"]    
  #  @audio3.subject.should == @attributes_hash["subject"]
  #  @audio3.source.should == @attributes_hash["source"]
  #  @audio3.geographical_coverage.should == @attributes_hash["geographical_coverage"]
  #  @audio3.temporal_coverage.should == @attributes_hash["temporal_coverage"]
  #  @audio3.should be_valid
  #end

  it "should have the specified datastreams" do
    # Check for descMetadata datastream with MODS in it
    @audio.attached_files.keys.should include(:descMetadata)
    @audio.descMetadata.should be_kind_of DRI::Metadata::QualifiedDublinCore
    # Check for properties datastream
    @audio.attached_files.keys.should include(:properties)
    @audio.properties.should be_kind_of DRI::Metadata::Properties
  end

  it "should not be valid with no metadata" do
    @audio.should_not be_valid
  end

  it "should create a valid audio object when valid metadata is ingested" do
    # From ingestion
    @dc = fixture("audios/dublin_core_audio_sample1.xml")
    @ds = DRI::Metadata::QualifiedDublinCore.from_xml(@dc)
    @audio2 = DRI::QualifiedDublinCore.new
    @audio2.update_metadata @ds.to_xml
    @audio2.should be_valid
  end

  it "the status property should be set as 'draft' when a new Audio object is created" do
    @audio = DRI::QualifiedDublinCore.new
    @audio.status.should == "draft"
  end
     
  #it "should have the attributes of a audio and support update_attributes" do
  #  @audio.update_attributes( @attributes_hash )
  #  
  #  # These attributes have not been marked "unique" in the call to the delegate, which causes the results to be arrays
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
  #  @audio.title.should == @attributes_hash["title"]
  #  @audio.rights.should == @attributes_hash["rights"]
  #  @audio.description.should == @attributes_hash["description"]
  #  @audio.published_date.should == @attributes_hash["published_date"]
  #  @audio.creation_date.should == @attributes_hash["creation_date"]
  #  @audio.language.should == @attributes_hash["language"]
  #  @audio.role_pro.should == @attributes_hash["role_hst"]
  #  @audio.role_hst.should == @attributes_hash["role_pro"]
  #  @audio.role_aut.should == @attributes_hash["role_aut"]    
  #  @audio.subject.should == @attributes_hash["subject"]
  #  @audio.source.should == @attributes_hash["source"]
  #  @audio.geographical_coverage.should == @attributes_hash["geographical_coverage"]
  #  @audio.temporal_coverage.should == @attributes_hash["temporal_coverage"]
  #
  #end

  it "should validate the presence of the title metadata field" do
    # From ingestion
    @dc = fixture("audios/dublin_core_audio_notitle_sample.xml")
    @ds = DRI::Metadata::QualifiedDublinCore.from_xml(@dc)
    @audio2 = DRI::QualifiedDublinCore.new
    @audio2.update_metadata @ds.to_xml
    @audio2.should_not be_valid

    # From update_attributes assignment
    @audio = DRI::QualifiedDublinCore.new
    @attributes_hash[:title] = [""]
    @audio.update_attributes( @attributes_hash )
    @audio.should_not be_valid
    @audio = DRI::QualifiedDublinCore.new
    @attributes_hash.delete("title")
    @audio.update_attributes( @attributes_hash )
    @audio.should_not be_valid

    # From variable assignment
    @audio = DRI::QualifiedDublinCore.new
    @audio.description = ["blah"]
    @audio.rights = ["blah"]
    @audio.creator = ["blah"]
    @audio.type = ["Sound"]
    @audio.date = ["1916-04-01"]
    @audio.title = []
    @audio.should_not be_valid

    @audio.title = [""]
    @audio.should_not be_valid
  end

  it "should validate the presence of the description metadata field" do
    # From ingestion
    @dc = fixture("audios/dublin_core_audio_nodescription_sample.xml")
    @ds = DRI::Metadata::QualifiedDublinCore.from_xml(@dc)
    @audio.update_metadata @ds.to_xml
    @audio.should_not be_valid

    # From update_attributes assignment
    @audio = DRI::QualifiedDublinCore.new
    @attributes_hash[:description] = [""]
    @audio.update_attributes( @attributes_hash )
    @audio.should_not be_valid
    @audio = DRI::QualifiedDublinCore.new
    @attributes_hash.delete("description")
    @audio.update_attributes( @attributes_hash )
    @audio.should_not be_valid

    # From variable assignment
    @audio = DRI::QualifiedDublinCore.new
    @audio.title = ["blah"]
    @audio.rights = ["blah"]
    @audio.creator = ["blah"]
    @audio.type = ["Sound"]
    @audio.date = ["1916-04-01"]
    @audio.description = []
    @audio.should_not be_valid

    @audio.description = [""]
    @audio.should_not be_valid

  end

  it "should validate the presence of the rights metadata field" do
    # From ingestion
    @dc = fixture("audios/dublin_core_audio_norights_sample.xml")
    @ds = DRI::Metadata::QualifiedDublinCore.from_xml(@dc)
    @audio2 = DRI::QualifiedDublinCore.new
    @audio2.update_metadata @ds.to_xml
    @audio2.should_not be_valid

    # From update_attributes assignment
    @audio = DRI::QualifiedDublinCore.new
    @attributes_hash[:rights] = [""]
    @audio.update_attributes( @attributes_hash )
    @audio.should_not be_valid
    @audio = DRI::QualifiedDublinCore.new
    @attributes_hash.delete("rights")
    @audio.update_attributes( @attributes_hash )
    @audio.should_not be_valid

    # From variable assignment
    @audio = DRI::QualifiedDublinCore.new
    @audio.title = ["blah"]
    @audio.rights = []
    @audio.creator = ["blah"]
    @audio.type = ["Sound"]
    @audio.description = ["blah"]
    @audio.date = ["1916-04-01"]
    @audio.should_not be_valid

    @audio.rights = [""]
    @audio.should_not be_valid
  end

  it "should validate the presence of the type metadata field" do
    # From ingestion
    @dc = fixture("audios/dublin_core_audio_notype_sample.xml")
    @ds = DRI::Metadata::QualifiedDublinCore.from_xml(@dc)
    @audio2 = DRI::QualifiedDublinCore.new
    @audio2.update_metadata @ds.to_xml
    @audio2.should_not be_valid

    # From update_attributes assignment
    @audio = DRI::QualifiedDublinCore.new
    @attributes_hash[:type] = [""]
    @audio.update_attributes( @attributes_hash )
    @audio.should_not be_valid
    @audio = DRI::QualifiedDublinCore.new
    @attributes_hash.delete("type")
    @audio.update_attributes( @attributes_hash )
    @audio.should_not be_valid

    # From variable assignment
    @audio = DRI::QualifiedDublinCore.new
    @audio.title = ["blah"]
    @audio.rights = ["blah"]
    @audio.creator = ["blah"]
    @audio.type = []
    @audio.date = ["1916-04-01"]
    @audio.description = ["blah"]
    @audio.should_not be_valid

    @audio.type = [""]
    @audio.should_not be_valid
  end

  it "should validate the presence of the date metadata fields" do
    # From ingestion
    @dc = fixture("audios/dublin_core_audio_nodate_sample.xml")
    @ds = DRI::Metadata::QualifiedDublinCore.from_xml(@dc)
    @audio2 = DRI::QualifiedDublinCore.new
    @audio2.update_metadata @ds.to_xml
    @audio2.should_not be_valid

    # From update_attributes assignment
    @audio = DRI::QualifiedDublinCore.new
    @attributes_hash[:type] = [""]
    @audio.update_attributes( @attributes_hash )
    @audio.should_not be_valid
    @audio = DRI::QualifiedDublinCore.new
    @attributes_hash.delete("creation_date")
    @attributes_hash.delete("published_date")
    @audio.update_attributes( @attributes_hash )
    @audio.should_not be_valid

    # From variable assignment
    @audio = DRI::QualifiedDublinCore.new
    @audio.title = ["blah"]
    @audio.rights = ["blah"]
    @audio.creator = ["blah"]
    @audio.date = []
    @audio.type = ["Sound"]
    @audio.description = ["blah"]
    @audio.should_not be_valid

    @audio.date = [""]
    @audio.should_not be_valid
  end
  
  after(:each) do
    unless @audio.new_record?
      @audio.delete
    end
  end

end
