module DRI

  module Metadata

    class Marc < DRI::Metadata::Base

      # OM (Opinionated Metadata) terminology mapping to an Marc Collection
      # df=datafield, sf=subfield,
      set_terminology do |t|
        t.root(:path=>"collection", :namespace_prefix => nil)
        
         t.record(:path=>"record", :namespace_prefix=>nil) {

            # Mandatory; DC Type
            t.leader(:path=>"leader", :namespace_prefix=>nil, :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])

            t.controlfield_001(:path=>"controlfield", :namespace_prefix => nil, :attributes=>{:tag => "001"})
            t.controlfield_003(:path=>"controlfield", :namespace_prefix => nil, :attributes=>{:tag => "003"})
            t.controlfield_005(:path=>"controlfield", :namespace_prefix => nil, :attributes=>{:tag => "005"})
            t.controlfield_008(:path=>"controlfield", :namespace_prefix => nil, :attributes=>{:tag => "008"})

            # Load from Vocabulary
            DRI::Vocabulary::marcDatafields.each do |df|
              t.send( "df_"+df[:code], :path=>"datafield", :namespace_prefix=>nil, :attributes=>{:tag => "#{df[:code]}", :ind1 => "#{df[:ind1]}", :ind2 => "#{df[:ind2]}"}){
                df[:sf].each do |sf|
                  t.send ("sf_#{df[:code]}#{sf}"), :path => "subfield", :namespace_prefix=>nil, :attributes=>{:code => "#{sf}"}, :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable]
                end
            }
            end
        }
       
        DRI::Vocabulary::marcDatafields.each do |df|
            df[:sf].each do |sf|
              t.send ("sf_" + df[:code] + sf), :proxy=>[:record, ("df_" + df[:code]).to_sym, ("sf_" + df[:code] + sf).to_sym]
            end
        end
 
        # Mandatory fields
        t.title(:ref => [:sf_245a])
        t.description(:ref => [:sf_500a])
        t.type(:proxy => [:record, :leader])
        t.creator(:ref => [:sf_100a])
        t.rights(:ref => [:sf_506a])
        t.creation_date(:ref => [:sf_260c])

        t.controlfield_001(:proxy => [:record, :controlfield_001])
        t.controlfield_003(:proxy => [:record, :controlfield_003])
        t.controlfield_005(:proxy => [:record, :controlfield_005])
        t.controlfield_008(:proxy => [:record, :controlfield_008])

      end # set_terminology

      # Build the xml doc
      def self.xml_template
        builder = Nokogiri::XML::Builder.new do |xml|
          # xml.doc.create_internal_subset(
          #   'ead',
          #   "+//ISBN 1-931666-00-8//DTD ead.dtd (Encoded Archival Description (EAD) Version 2002)//EN",
          #   ""
          # )
          xml.collection("xmlns:marc"=>"http://www.loc.gov/MARC21/slim",
                   "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
                   "xsi:schemaLocation"=>"http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd") {
              xml.record {
                xml.leader
              }
          }
        end
        return builder.doc
      end

      def to_solr(solr_doc=Hash.new)
        solr_doc = super(solr_doc)

        # Retrieve list of all people and add them to facet and search indexes in solr document
        # person_array = get_person_array()

        # solr_doc.merge!(Solrizer.solr_name('person', :facetable) => person_array)
        # solr_doc.merge!(Solrizer.solr_name('person', :stored_searchable, type: :text) => person_array | DRI::Metadata::Transformations.transform_name(person_array))

        # title_sorted - A SOLR index for sorting titles
        # if (title.length > 0)
        #   sorted_title = DRI::Metadata::Transformations.transform_title_for_sort(title[0])
        #   if (sorted_title != "")
        #     solr_doc.merge!(Solrizer.solr_name('title_sorted', :stored_sortable, type: :string) => [sorted_title])
        #   end
        # end

        solr_doc.merge!(Solrizer.solr_name('title', :stored_sortable, type: :string) => [title])

        # all_metadata - A SOLR index of all the text contained in the XML document
        # all_metadata = ""
        # ng_xml.xpath("//text()").each do |text_node|
        #   all_metadata += text_node.text
        #   all_metadata += " "
        # end
        # solr_doc.merge!(Solrizer.solr_name("all_metadata", :stored_searchable, type: :text) => [all_metadata])

        # Split facets into different languages based on xml:lang
        # faceted_language_indexes = Hash.new
        # faceted_language_indexes.merge! split_array_into_languages("subject")
        # faceted_language_indexes.merge! split_array_into_languages("coverage")
        # faceted_language_indexes.merge! split_array_into_languages("temporal_coverage")
        # faceted_language_indexes.merge! split_array_into_languages("geographical_coverage")

        # faceted_language_indexes.each do | key, value |
        #   solr_doc.merge!(Solrizer.solr_name(key, :stored_searchable, type: :text) => value)
        #   solr_doc.merge!(Solrizer.solr_name(key, :facetable, type: :text) => value)
        # end

        # Split date ranges into separate indexes
        #date_ranges = Transformations.transform_date_ranges({ "date" => date, "published_date" => published_date, "creation_date" => creation_date})
        #solr_doc.merge!(date_ranges)

        solr_doc
      end

      def custom_validations
        errors = Hash.new

        title_result = false
        type_result = false
        description_result = false
        creator_result = false
        rights_result = false
        creation_date_result = false

        title.each do |curr_title|
          title_result = true unless curr_title.blank?
        end

        type.each do |curr_type|
          type_result = true unless curr_type.blank?
        end

        description.each do |curr_description|
          description_result = true unless curr_description.blank?
        end

        creator.each do |curr_creator|
          creator_result = true unless curr_creator.blank?
        end

        rights.each do |curr_rights|
          rights_result = true unless curr_rights.blank?
        end

        creation_date.each do |curr_creation_date|
          creation_date_result = true unless curr_creation_date.blank?
        end


        errors[:title] = "can't be blank" if title_result == false
        errors[:type] = "can't be blank" if type_result == false
        errors[:description] = "can't be blank" if description_result == false
        errors[:creator] = "can't be blank" if creator_result == false
        errors[:creation_date] = "can't be blank" if creation_date_result == false
        errors[:rights] = "can't be blank" if rights_result == false


        errors
      end

      def interchangeable?
        false
      end
    end

  end

end
