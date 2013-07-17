# encoding: utf-8
# spec/metadata/encoded_archival_description_spec.rb
require 'spec_helper'

describe "DRI::Metadata::EncodedArchivalDescription" do

  before(:each) do
    @ead = fixture("collections/ead_sample.xml")
    @ds = DRI::Metadata::EncodedArchivalDescription.from_xml(@ead)
  end

  it "should expose common metadata info for EAD collection" do
    # Sample metadata taken from Appendix C of Library of Congress' official EAD documentation
    @ds.title.should == ["Series Records of territorial governor Willis A. Gorman,"]
    @ds.description.should == ["Subject files, correspondence, appointments, pardon records, reports from territorial officers, requests for return of fugitives, and miscellany."]
    @ds.language.should == ["en"]
    @ds.creator.should == ["Agency:Minnesota. Governor (1853-1857 : Gorman)."]
    @ds.subject.should == ["Civil-military relations--Minnesota.",
                            "Extraditions--Minnesota.",
                            "Federal government--Minnesota.",
                            "Indians of North America—Government relations--1789-1869.",
                            "Land titles--Minnesota--Registration and transfer.",
                            "Pardons--Minnesota.",
                            "Winnebago Indians--Treaties."]
    @ds.persname_coverage.should == ["Gorman, Willis Arnold, 1816-1876."]
    @ds.corpname_coverage.should == ["Minnesota Territory."]
    @ds.get_person_array.should == ["Gorman, Willis Arnold, 1816-1876.","Minnesota Territory.","Agency:Minnesota. Governor (1853-1857 : Gorman)."]
    @ds.geographical_coverage.should == ["Minnesota--Officials and employees--Selection and appointment.",
                            "Minnesota--Politics and government--1849-1858."]
    @ds.creation_date.should == ["1852"]
  end

end
