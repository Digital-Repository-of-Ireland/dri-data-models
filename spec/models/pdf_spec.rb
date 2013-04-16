# spec/modules/pdf_spec.rb
require 'spec_helper'


describe DRI::Model::Pdfdoc do
  
  before(:each) do
    # This gives you a test article object that can be used in any of the tests
    @pdfdoc = DRI::Model::Pdfdoc.new

    @attributes_hash = {
      "title" => "A PDF Title",
      "rights" => "This is a statement about the rights associated with this object",
      "author" => ["Collins, Michael"],
      "editor" => ["DeValera, Eamonn", "Connolly, James"],
      "language" => "ga",
      "description" => "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
      "creation_date" => "1916-01-01",
      "source" => ["CD nnn nuig"],
      "geographical_coverage" => ["Dublin"],
      "temporal_coverage" => ["1900s"],
      "subject" => ["Ireland","something else"]
    }

  end

  it "should have the specified datastreams" do
    # Check for descMetadata datastream with MODS in it
    @pdfdoc.datastreams.keys.should include("descMetadata")
    @pdfdoc.descMetadata.should be_kind_of DRI::Metadata::DublinCorePdfdoc
    # Check for rightsMetadata datastream
    @pdfdoc.datastreams.keys.should include("rightsMetadata")
    @pdfdoc.rightsMetadata.should be_kind_of Hydra::Datastream::RightsMetadata
    # Check for properties datastream
    @pdfdoc.datastreams.keys.should include("properties")
    @pdfdoc.properties.should be_kind_of DRI::Metadata::Properties
  end

  it "should have the ability to add references to pdf files" do
    @pdfdoc.add_file_reference("masterContent", {:url => "http://johndadlez.com/MP3/BTAS2_D1_45_Gotham.mp3", :mimeType => "application/pdf"})
    @pdfdoc.datastreams.keys.should include("masterContent")
  end

  it "should not allow random files to be added" do
    @pdfdoc.add_file_reference("randomfile", {:url => "http://johndadlez.com/MP3/BTAS2_D1_45_Gotham.mp3", :mimeType => "application/pdf"})
    @pdfdoc.datastreams.keys.should_not include("randomfile")
  end

  it "should not be vaild with no metadata" do
    @pdfdoc.should_not be_valid
  end

  it "should create a valid pdfdoc object when valid metadata is ingested" do
    # From ingestion
    @dc = fixture("pdfs/dublin_core_pdfdoc_sample.xml")
    @ds = DRI::Metadata::DublinCorePdfdoc.from_xml(@dc)
    @pdfdoc2 = DRI::Model::Pdfdoc.new
    @pdfdoc2.datastreams["descMetadata"] = @ds
    @pdfdoc2.should be_valid
  end

  it "the status property should be set as 'draft' when a new Audio object is created" do
    @pdfdoc = DRI::Model::Pdfdoc.new
    @pdfdoc.status.should == "draft"
  end
     
  it "should have the attributes of a pdfdoc and support update_attributes" do
    @pdfdoc.update_attributes( @attributes_hash )
    
    # These attributes have been marked "unique" in the call to delegate, which causes the results to be singular
    @pdfdoc.title.class.to_s.should == 'String'
    @pdfdoc.rights.class.to_s.should == 'String'
    @pdfdoc.description.class.to_s.should == 'String'
    @pdfdoc.language.class.to_s.should == 'String'
    @pdfdoc.creation_date.class.to_s.should == 'String'

    # These attributes have not been marked "unique" in the call to the delegate, which causes the results to be arrays
    @pdfdoc.author.class.to_s.should == 'Array'
    @pdfdoc.editor.class.to_s.should == 'Array'
    @pdfdoc.subject.class.to_s.should == 'Array'
    @pdfdoc.source.class.to_s.should == 'Array'
    @pdfdoc.geographical_coverage.class.to_s.should == 'Array'
    @pdfdoc.temporal_coverage.class.to_s.should == 'Array'

    # The value should match what was set in the attributes_hash above
    @pdfdoc.title.should == @attributes_hash["title"]
    @pdfdoc.rights.should == @attributes_hash["rights"]
    @pdfdoc.description.should == @attributes_hash["description"]
    @pdfdoc.creation_date.should == @attributes_hash["creation_date"]
    @pdfdoc.language.should == @attributes_hash["language"]
    @pdfdoc.author.should == @attributes_hash["author"]
    @pdfdoc.editor.should == @attributes_hash["editor"]    
    @pdfdoc.subject.should == @attributes_hash["subject"]
    @pdfdoc.source.should == @attributes_hash["source"]
    @pdfdoc.geographical_coverage.should == @attributes_hash["geographical_coverage"]
    @pdfdoc.temporal_coverage.should == @attributes_hash["temporal_coverage"]
 
  end

  it "should automatically assign language=en where none is supplied" do
    # From ingestion
    @dc = fixture("pdfs/dublin_core_pdfdoc_nolang_sample.xml")
    @ds = DRI::Metadata::DublinCorePdfdoc.from_xml(@dc)
    @pdfdoc2 = DRI::Model::Pdfdoc.new
    @pdfdoc2.datastreams["descMetadata"] = @ds
    @pdfdoc2.save
    @pdfdoc2.language.should == "en"
 
    # From variable assignment
    @attributes_hash.delete("language")

    @pdfdoc.update_attributes( @attributes_hash )

    @pdfdoc.language.should == "en"

  end

  it "should validate the presence of the title metadata field" do
    # From ingestion
    @dc = fixture("pdfs/dublin_core_pdfdoc_notitle_sample.xml")
    @ds = DRI::Metadata::DublinCorePdfdoc.from_xml(@dc)
    @pdfdoc2 = DRI::Model::Pdfdoc.new
    @pdfdoc2.datastreams["descMetadata"] = @ds
    @pdfdoc2.should_not be_valid

    # From variable assignment
    @attributes_hash["title"] = ""

    @pdfdoc.update_attributes( @attributes_hash )

    @pdfdoc.should_not be_valid

  end

  it "should validate the presence of the rights metadata field" do
    # From ingestion
    @dc = fixture("pdfs/dublin_core_pdfdoc_norights_sample.xml")
    @ds = DRI::Metadata::DublinCorePdfdoc.from_xml(@dc)
    @pdfdoc2 = DRI::Model::Pdfdoc.new
    @pdfdoc2.datastreams["descMetadata"] = @ds
    @pdfdoc2.should_not be_valid

    # From variable assignment
    @attributes_hash["rights"] = ""

    @pdfdoc.update_attributes( @attributes_hash )

    @pdfdoc.should_not be_valid

  end

  it "should have type 'Sound'" do
  end    

end
