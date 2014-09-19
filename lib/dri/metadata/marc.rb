module DRI

  module Metadata

    class Marc < DRI::Metadata::Base
      # OM (Opinionated Metadata) terminology mapping to an EAD Collection
      set_terminology do |t|
        t.root(:path=>"*", :namespace_prefix => nil)

        t.collection(:path=>"collection", :namespace_prefix => nil) {
          t.title(:namespace_prefix=>nil, :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
          t.description(:namespace_prefix=>nil, :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
          t.type(:namespace_prefix=>nil, :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
          t.rights(:namespace_prefix=>nil, :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
          t.licence(:namespace_prefix=>nil, :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
          t.creator(:namespace_prefix=>nil, :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
          t.creation_date(:namespace_prefix=>nil, :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
          t.record(:path=>"record", :namespace_prefix => nil) {
            t.leader(:path=>"leader", :namespace_prefix => nil)
            t.controlfield_001(:path=>"controlfield", :namespace_prefix => nil, :attributes=>{:tag => "001"})
            t.controlfield_003(:path=>"controlfield", :namespace_prefix => nil, :attributes=>{:tag => "003"})
            t.controlfield_005(:path=>"controlfield", :namespace_prefix => nil, :attributes=>{:tag => "005"})
            t.controlfield_008(:path=>"controlfield", :namespace_prefix => nil, :attributes=>{:tag => "008"})

            # DRI::Vocabulary::marcDatafields.each do |datafield|
            #   #  Create Datafield
            #   t.send( "datafield_"+datafield[0], :path=>"datafield", :namespace_prefix=>nil, :attributes=>{:tag => datafield[0], :ind1 => datafield[1], :ind2 => datafield[2]}){
            #     # t.send "subfield", :path => "subfield", :namespace_prefix => nil, :attributes=>{:code => "a"}
            #     # t.subfield(:path => "subfield", :namespace_prefix => nil, :attributes=>{:code => "a"})
            #     # t.subfield(:proxy => [:collection, :record, ("datafield_" + datafield[0]).to_sym, ("subfield_" + subfield).to_sym])
            #     # t.send :proxy => [:collection, :record, ("datafield_" + datafield[0]).to_sym, ("subfield_" + subfield).to_sym]
            #
            #     # Format of the subfield: datafield-ind1-ind2-subfield ie:
            #     # 650_ind1_1_ind2_0_subfield_a,
            #     # empty attributes are replaced with underscore '_' ie:
            #     # 650_ind1___ind2___subfield_a
            #
            #     datafield[3].each do |subfield|
            #       t.send ("datafield_" + datafield[0]+"_ind1_"+ datafield[1].sub( ' ', '_') + "_ind2_" + datafield[1].sub( ' ', '_') +"_subfield_"+ subfield), :path => "subfield", :namespace_prefix=>nil, :attributes=>{:code => subfield}
            #     end
            #   }
            # end

            t.datafield_336(:path => "datafield", :namespace_prefix => nil, :attributes=>{:tag => "336", :ind1 => " ", :ind2 => " "}) {
              t.datafield_336_ind1__ind2__subfield_a(:path => "subfield", :namespace_prefix => nil, :attributes=>{:code => "a"})
            }

            t.datafield_010(:path => "datafield", :namespace_prefix => nil, :attributes=>{:tag => "010", :ind1 => " ", :ind2 => " "}) {
              t.datafield_010_ind1__ind2__subfield_a(:path => "subfield", :namespace_prefix => nil, :attributes=>{:code => "a"})
            }

            # We need to keep track of the unitid in order to sync this XML snippet to the correct
            # component tag in the complete EAD XML datastream in the collection object!
            # t.eadid(:path=>"eadid", :namespace_prefix => nil) {
            #   t.repository_code(:path => {:attribute=>"mainagencycode"}, :namespace_prefix => nil)
            #   t.country_code(:path => {:attribute=>"countrycode"}, :namespace_prefix => nil)
            #   t.identifier(:path => {:attribute=>"identifier"}, :namespace_prefix => nil)
            # }
            # t.filedesc {
            #   t.titlestmt {
            #     t.title(:path=>"titleproper")
            #   }
            # }
          }
          # t.archdesc {
          #   t.subject(:path=>"subject")
          #   t.name_coverage(:path=>"name")
          #   t.persname_coverage(:path=>"persname")
          #   t.corpname_coverage(:path=>"corpname")
          #   t.geographical_coverage(:path=>"geogname")
          #   t.ead_level(:path => {:attribute=>"level"}, :namespace_prefix => nil)
          #   t.did(:path => "did", :namespace_prefix => nil) {
          #     t.abstract()
          #     t.language(:path=>"langmaterial")
          #     t.creator(:path=>"origination")
          #
          #     t.creation_date(:path=>"unitdate") {
          #       t.normal(:path => {:attribute=>"normal"}, :namespace_prefix => nil)
          #       t.datechar(:path => {:attribute=>"datechar"}, :namespace_prefix => nil)
          #     }
          #     t.physdesc(:path=>"physdesc") {
          #       t.type(:path=>"genreform")
          #     }
          #     # t.dao(:path=>"dao") {
          #     #   t.href(:path => {:attribute=>"href"}, :namespace_prefix => nil)
          #     # }
          #   }
          #   t.bioghist {
          #
          #   }
          #   t.scopecontent {
          #
          #   }
          # }
        }
        t.title(:proxy => [:collection, :title])
        t.description(:proxy => [:collection, :description])
        t.type(:proxy => [:collection, :type])
        t.rights(:proxy => [:collection, :rights])
        t.licence(:proxy => [:collection, :licence])
        t.creator(:proxy => [:collection, :creator])
        t.creation_date(:proxy => [:collection, :creation_date])

        t.leader(:proxy => [:collection, :record, :leader])
        t.controlfield_001(:proxy => [:collection, :record, :controlfield_001])
        t.controlfield_003(:proxy => [:collection, :record, :controlfield_003])
        t.controlfield_005(:proxy => [:collection, :record, :controlfield_005])
        t.controlfield_008(:proxy => [:collection, :record, :controlfield_008])

        t.datafield_336_ind1__ind2__subfield_a(:proxy=> [:collection, :record, :datafield_336, :datafield_336_ind1__ind2__subfield_a], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.datafield_010_ind1__ind2__subfield_a(:proxy=> [:collection, :record, :datafield_010, :datafield_010_ind1__ind2__subfield_a], :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])


        # ["020", ["0", "1"], ["0", "4"], ["a", "b"], ["021", ["0", "1"], ["0", "4"], ["a", "b"]]].each do |datafield|
        #   t.send "datafield_"+datafield[0], :proxy=> [:collection, :record, :datafield_020]
        # end

        # DRI::Vocabulary::marcDatafields.each do |datafield|
        #     t.send "datafield_"+datafield[0], :proxy=> [:collection, :record, ("datafield_" + datafield[0]).to_sym]
        #     #  Loop over Subfields from vocabulary
        #     datafield[3].each do |subfield|
        #       t.send ("datafield_" + datafield[0]+"_ind1_"+ datafield[1].sub( ' ', '_') + "_ind2_" + datafield[1].sub( ' ', '_') +"_subfield_"+ subfield), :proxy=>[:collection, :record, ("datafield_" + datafield[0]).to_sym, ("subfield_" + subfield).to_sym]
        #     end
        # end

        # t.datafield_020(:proxy=> [:collection, :record, :datafield_020])
        # t.datafield_021(:proxy=> [:collection, :record, :datafield_021])


        # t.subfield(:proxy => [:collection, :record, :datafield, :subfield])

        # t.ead_level(:proxy => [:ead, :archdesc, :ead_level])
        # t.unitid(:proxy => [:ead, :eadheader, :eadid])
        # t.repository_code(:proxy => [:ead, :eadheader, :eadid, :repository_code])
        # t.country_code(:proxy => [:ead, :eadheader, :eadid, :country_code])
        # t.identifier(:proxy => [:ead, :eadheader, :eadid, :identifier])
        # t.title(:proxy => [:ead, :eadheader, :filedesc, :titlestmt, :title])
        # t.abstract(:proxy => [:ead, :archdesc, :did,  :abstract])
        # t.creation_date(:proxy => [:ead, :archdesc, :did, :creation_date])
        # t.language(:proxy => [:ead, :archdesc, :did, :language])
        # t.creator(:proxy => [:ead, :archdesc, :did, :creator])
        # t.scope_content(:proxy => [:ead, :archdesc, :scopecontent])
        # t.subject(:proxy => [:ead, :archdesc, :subject])
        # t.name_coverage(:proxy => [:ead, :archdesc,  :name_coverage])
        # t.persname_coverage(:proxy => [:ead, :archdesc, :persname_coverage])
        # t.corpname_coverage(:proxy => [:ead, :archdesc, :corpname_coverage])
        # t.geographical_coverage(:proxy => [:ead, :archdesc,  :geographical_coverage])
        # t.physdesc(:proxy => [:ead, :archdesc, :did, :physdesc])
        # t.type(:proxy => [:ead, :archdesc, :did, :physdesc, :type])
        # t.bioghist(:proxy => [:ead, :archdesc, :bioghist])

      end # set_terminology

      # Build the xml doc
      def self.xml_template
        builder = Nokogiri::XML::Builder.new do |xml|
          # xml.doc.create_internal_subset(
          #   'ead',
          #   "+//ISBN 1-931666-00-8//DTD ead.dtd (Encoded Archival Description (EAD) Version 2002)//EN",
          #   ""
          # )
          xml.marc {
            xml.collection {
              #   xml.leader
              # xml.filedesc {
              #   xml.titlestmt {
              #     xml.titleproper
              #   }
              # }
              # }
              # xml.archdesc {
              #   xml.did
              #   xml.dsc
            }
          }
        end
        return builder.doc
      end

    end

  end

end