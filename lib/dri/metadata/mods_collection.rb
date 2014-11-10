module DRI

  module Metadata

    # An ActiveFedora datastream that interacts with a collection of MODS records.
    # MODS Schema version changed to 3.5 (July 8, 2013) based on DRI MODS guidelines.
    class ModsCollection < DRI::Metadata::Base

      # Set OM (Opinionated Metadata) terminology
      def self.load_inherited_terminology
        set_terminology do |t|
          t.root(:path=>"modsCollection", :xmlns=>"http://www.loc.gov/mods/v3",
                 :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-5.xsd")
          t.mods(:path=>"mods") {
            t.title_info(:path=>"titleInfo") {
              t.main_title(:path=>"title", :label=>"title")
              t.language(:path=>{:attribute=>"lang"})
            }
            t.language(:path=>"language"){
              t.lang_code(:path=>"languageTerm", :attributes=>{:type=>"code"})
            }
            t.abstract
            t.subject (:path=>"subject") {
              t.topic(:path=>"topic")
            }

            t.name_ {
              # this is a namepart
              t.namePart(:type=>:string, :label=>"generic name")

              t.affiliation
              t.institution(:path=>"affiliation", :index_as=>[:facetable], :label=>"organization")
              t.displayForm
              t.role(:ref=>[:role])
              t.description
              t.date(:path=>"namePart", :attributes=>{:type=>"date"})
              t.last_name(:path=>"namePart", :attributes=>{:type=>"family"})
              t.first_name(:path=>"namePart", :attributes=>{:type=>"given"}, :label=>"first name")
              t.terms_of_address(:path=>"namePart", :attributes=>{:type=>"termsOfAddress"})
              t.computing_id
            }
            # lookup :person, :first_name
            t.person(:ref=>:name, :attributes=>{:type=>"personal"})
            t.department(:proxy=>[:person,:description])
            t.organization(:ref=>:name, :attributes=>{:type=>"corporate"})

            t.role {
              t.text(:path=>"roleTerm",:attributes=>{:type=>"text"})
              t.code(:path=>"roleTerm",:attributes=>{:type=>"code"})
            }
          }
          # Term proxies definition
          t.title(:proxy=>[:mods, :title_info, :main_title], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
          t.language(:proxy=>[:mods, :language], :index_as=>[Descriptors.cleaned_searchable, Descriptors.language_facetable])
          t.abstract(:proxy=>[:mods, :abstract], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
          t.subject(:proxy=>[:mods, :subject, :topic], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable])

          # FIXME - comes from QDC, Generate MARC Relators fields from the MARC Relators vocabulary
          DRI::Vocabulary::marcRelators.each do |role|
            t.send "role_"+role, :path=>role, :namespace_prefix=>"marcrel", :index_as=>[Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable]
          end
        end

      end

      # Build the xml doc
      def self.xml_template
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.modscollection(:version=>"3.3", "xmlns:xlink"=>"http://www.w3.org/1999/xlink",
              "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
              "xmlns"=>"http://www.loc.gov/mods/v3",
              "xsi:schemaLocation"=>"http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-5.xsd") {
            xml.mods {
            }
          }
        end
        return builder.doc
      end

      # The same as for EAD - we need to update the individual records within a MODS collection
      def synchronize_metadata_on_save
        @synchronize_metadata_on_save || true
      end

      def interchangeable?
        false
      end

      def collection?
        true
      end

      # Load terminology
      load_inherited_terminology
    end # class

  end # module

end # module
