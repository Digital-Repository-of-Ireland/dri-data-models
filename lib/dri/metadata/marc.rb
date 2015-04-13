module DRI

  module Metadata

    class Marc < DRI::Metadata::Base

      # OM (Opinionated Metadata) terminology mapping to an Marc Collection
      # df=datafield, sf=subfield,
      set_terminology do |t|
        t.root(:path=>"collection", :namespace_prefix => nil)

         t.record(:path=>"record", :namespace_prefix=>nil) {

            t.leader(:path=>"leader", :namespace_prefix=>nil, :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])

            t.controlfield {
              t.controlfield_tag(:path=>{:attribute=>"tag"})
            }

            t.datafield {
              t.tag(:path=>{:attribute=>"tag"})
              t.ind1(:path=>{:attribute=>"ind1"})
              t.ind2(:path=>{:attribute=>"ind2"})
              t.subfield(:path => "subfield") {
                t.code(:path=>{:attribute=>"code"})
              }
            }

        }

        # Mandatory fields
        t.title(:path => 'record/datafield[@tag="245"]/subfield[@code="a" or @code="b" or @code="c"]', :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.description(:path => 'record/datafield[@tag="300" or @tag="500" or @tag="520"]', :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.creator(:path => 'record/datafield[@tag="100" or @tag="110" or @tag="700" or @tag="710" or @tag="711"]', :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.rights(:path => 'record/datafield[@tag="506" or @tag="540"] | //record/datafield[@tag="542"]/subfield[@code="f"]', :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        t.creation_date(:path => 'record/datafield[@tag="260" or @tag="264"]/subfield[@code="c"] | //record/controlfield[@tag="008"]', :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        
        # common fields
        t.language(:path => 'record/datafield[@tag="041"]/subfield[@code="a"]', :index_as=>[Descriptors.cleaned_searchable, Descriptors.language_facetable])
        t.publisher(:path => 'record/datafield[@tag="260"]/subfield[@code="b"] | //record/datafield[@tag="710"]/subfield[@code="x"]', :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable])
        t.published_date(:path => 'record/datafield[@tag="260"]/subfield[@code="c"]', :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, :sortable])
        t.author(:path => 'record/datafield[@tag="100" or @tag="110" or @tag="111"]/subfield[@code="a"] | //record/datafield[@tag="740"]/subfield[@code="a"]', :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable, Descriptors.cleaned_facetable])
        t.subject(:path => 'record/datafield[@tag="600" or @tag="610" or @tag="611" or @tag="630" or @tag="650" or @tag="653"]/subfield[@code="a"]', :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable])
        t.contributor(:path => 'record/datafield[@tag="700"]/subfield[@code="a"]', :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        # TODO Add mapping to Source
        t.source(:path => 'record/datafield[@tag="830" or @tag="490"]/subfield[@code="a"]', :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        # marc fields
        t.leader(:proxy => [:record, :leader])

        # Controlfields
        t.controlfield(:ref => [:record, :controlfield])
        t.controlfield_tag(:proxy => [:record, :controlfield, :controlfield_tag])
        # Datafields
        t.datafield(:ref => [:record, :datafield])
        t.datafield_tag(:proxy => [:record, :datafield, :tag])
        t.datafield_ind1(:proxy => [:record, :datafield, :ind1])
        t.datafield_ind2(:proxy => [:record, :datafield, :ind2])

        @marc ||= YAML.load(File.read(File.expand_path('../../vocabulary_marc.yaml', __FILE__)))
        @marc[:controlfield].each do |cf|
          t.send ("cf_#{cf[1][:tag]}"), :path => "record/controlfield[@tag='#{cf[1][:tag]}']", :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable, Descriptors.cleaned_facetable]
        end

        @marc[:datafield].each do |section|
          section[1].each do |df|
              df[1][:subfield].each do |sf|
                t.send ("df_#{df[1][:tag]}#{sf[1][:code]}"), :path => "record/datafield[@tag='#{df[1][:tag]}']/subfield[@code='#{sf[1][:code]}']", :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable, Descriptors.cleaned_facetable]
              end
          end
        end

        # NCCB Specific fields
        t.add_title_info(:path => 'record/datafield[@tag="130" or @tag="246"]/subfield[@code="a"]', :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable, Descriptors.cleaned_facetable])
        t.author(:path => 'record/datafield[@tag="100" or @tag="110" or @tag="111"]/subfield[@code="a"]', :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable])
        t.other_names(:path => 'record/datafield[@tag="700" or @tag="720"]/subfield[@code="a"]', :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable])
        t.notes(:path => 'record/datafield[@tag="500" or @tag="504" or @tag="505" or @tag="510" or @tag="520" or @tag="530" or @tag="546"]/subfield[@code="a"]', :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable])
        t.shelfmark(:path => 'record/datafield[@tag="082"]/subfield[@code="a"] | //record/datafield[@tag="852"]/subfield[@code="c"]', :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
        # Extra Facets:
        t.author_facet(:path => 'record/datafield[@tag="100" or @tag="110" or @tag="111" or @tag="700"]/subfield[@code="a"]', :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable])
        t.subject_name_facet(:path => 'record/datafield[@tag="600" or @tag="610" or @tag="611"]/subfield[@code="a"]', :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable])

        # Date Indices
        t.creation_date_idx(:path => "//record/controlfield[@tag='008']")

      end # set_terminology

      # From: Appendix 2 - Conversion rules for Leader06 - dc:Type mapping
      # http://www.loc.gov/marc/marc2dc.html
      def collection?
        # Leader/06 value for "dcmitype:collection": p (mixed materials)
        # Leader/07 value for "dcmitype:collection": c, s (collection or serial respectively)
        # Position 7 for 6th character and position 8 for 7th as Xpath substring first position is 1 rather that 0)
        leader_6_type = ng_xml.xpath('substring(//record/leader, 7, 1)')
        leader_7_type = ng_xml.xpath('substring(//record/leader, 8, 1)')
        ["p"].include?(leader_6_type) || ["c", "s"].include?(leader_7_type) ? true : false
      end

      # Build the xml doc
      def self.xml_template
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.collection("xmlns:marc"=>"http://www.loc.gov/MARC21/slim",
                   "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
                   "xsi:schemaLocation"=>"http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd") {
              xml.record {
                xml.leader
                xml.controlfield(:tag => '')
                xml.datafield(:tag => '', :ind1 => '#', :ind2 => '#') {
                  xml.subfield(:code => '')
                }
              }
          }
        end
        return builder.doc
      end

      def to_solr(solr_doc=Hash.new)
        solr_doc = super(solr_doc)

        solr_doc.merge!(Solrizer.solr_name('type', :stored_searchable) => type)
        solr_doc.merge!(Solrizer.solr_name('type', :facetable) => type)

        # Retrieve list of all people and add them to facet and search indexes in solr document
        person_array = get_person_array()

        solr_doc.merge!(Solrizer.solr_name('person', :facetable) => person_array)
        solr_doc.merge!(Solrizer.solr_name('person', :stored_searchable, type: :text) => person_array | DRI::Metadata::Transformations.transform_name(person_array))

        # all_metadata - A SOLR index of all the text contained in the XML document
        all_metadata = ""
        ng_xml.xpath("//text()").each do |text_node|
          all_metadata += text_node.text
          all_metadata += " "
        end
        solr_doc.merge!(Solrizer.solr_name("all_metadata", :stored_searchable, type: :text) => [all_metadata])

        solr_doc.merge!(Solrizer.solr_name('title_sorted', :stored_sortable, type: :string) => df_240a)
        solr_doc.merge!(Solrizer.solr_name('author_sorted', :stored_sortable, type: :string) => df_100a)
        solr_doc.merge!(Solrizer.solr_name('library_sorted', :stored_sortable, type: :string) => df_850a)

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

        date_ranges = get_creation_date_for_index() # ALL the date ranges

        # Creation date dateRange index
        cdate_ranges = date_ranges.select {|key, value| ["creation_date"].include?(key)}
        solr_doc.merge!(DRI::Metadata::Transformations::CREATION_DATE_RANGE_SOLR_FIELD => DRI::Metadata::Transformations::transform_date_ranges(cdate_ranges)) unless cdate_ranges == {}

        solr_doc
      end

      # Creates an array of all names stored in the metadata
      def get_person_array()
          contributor | creator | publisher
      end

      #
      # return Hash with creation_date array
      #
      def get_creation_date_for_index()
        dates_hash = Hash.new

        unless creation_date_idx == []
          dates_array = creation_date_idx.collect! do |value|
            date_s = value.slice(7, 4)
            date_e = value.slice(11, 4)
            if (!["\\\\", "    ", "####"].include?(date_s))
              !["\\\\", "    ", "####"].include?(date_e) ? "#{date_s}/#{date_e}" : date_s
            end
          end
          dates_hash['creation_date'] = dates_array unless dates_array == []
        end

        return dates_hash
      end

      def custom_validations
        errors = Hash.new

        title_result = false
        type_result = false
        description_result = false
        creator_result = false
        rights_result = false
        creation_date_result = false


        # Join all elements in array, get rid of carriage returns from the form (squish) and validate
        title_result = true unless title.join.squish == ""
        type_result = true unless type.join.squish == ""
        description_result = true unless description.join.squish == ""
        creator_result = true unless creator.join.squish == ""
        rights_result = true unless rights.join.squish == ""
        creation_date_result = true unless creation_date.join.squish == ""

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

      def type
        #[DRI::Vocabulary::marcType[ng_xml.xpath('substring(//record/leader, 7, 1)')]]
        # Position 7 (for 6th character as substring starts positions in 1 rather that 0)
        [DRI::Vocabulary::marcType_leader_6[ng_xml.xpath('substring(//record/leader, 7, 1)')]]
      end

      def add_datafields(datafields)
        ng_xml.search("//datafield").each do |n|
          n.remove
        end

        record = ng_xml.at('record')

        datafields.each do |index, datafield|
          node = Nokogiri::XML::Node.new('datafield', ng_xml)
          node['tag'] = datafield['datafield_tag'].first
          node['ind1'] = datafield['datafield_ind1'].first
          node['ind2'] = datafield['datafield_ind2'].first

          datafield['subfield'].each do |sub_index, subfield|
            subfield_node = Nokogiri::XML::Node.new('subfield', ng_xml)
            subfield_node['code'] = subfield['subfield_code'].first
            subfield_node.content = subfield['subfield_value'].first

            node.add_child(subfield_node) unless subfield_node.content.blank?
          end           

          record.add_child(node) unless node.children.empty?
        end
      end

      def add_controlfields(controlfields)
        ng_xml.search("//controlfield").each do |n|
          n.remove
        end
      
        record = ng_xml.at('record')

        controlfields.each do |index, controlfield|
            node = Nokogiri::XML::Node.new('controlfield', ng_xml)
            node['tag'] = controlfield['controlfield_tag'].first
            node.content = controlfield['controlfield_value'].first
            
            record.add_child(node)
        end
      end

      def self.marc_vocabulary
        @marc ||= YAML.load(File.read(File.expand_path('../../vocabulary_marc.yaml', __FILE__)))
      end
    end

  end
end
