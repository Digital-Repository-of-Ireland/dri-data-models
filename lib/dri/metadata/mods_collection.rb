module DRI

  module Metadata

    # An ActiveFedora datastream that interacts with a collection of MODS records.
    # MODS Schema version changed to 3.5 (July 8, 2013) based on DRI MODS guidelines.
    class ModsCollection < DRI::Metadata::Base
      include DRI::Utils

      # MODS XML constants.
      MODS_NS_PREFIX = "mods"
      MODS_NS = 'http://www.loc.gov/mods/v3'
      MODS_SCHEMA = 'http://www.loc.gov/standards/mods/v3/mods-3-5.xsd'
      CR_NS_PREFIX = "copyrightMD"
      CR_NS = "http://www.cdlib.org/inside/diglib/copyrightMD"

      # Set OM (Opinionated Metadata) terminology
      def self.load_inherited_terminology
        set_terminology do |t|
          t.root(:path =>"mods", :namespace_prefix => MODS_NS_PREFIX, "xmlns:#{CR_NS_PREFIX}" => CR_NS, :schema => MODS_SCHEMA)

          t.title_info(:path => "titleInfo", :namespace_prefix => MODS_NS_PREFIX) {
            t.main_title(:path => "title", :label => "title", :namespace_prefix => MODS_NS_PREFIX)
            t.subtitle(:path => "subTitle", :namespace_prefix => MODS_NS_PREFIX)
          }
          # Map to the mods record identifier (absolute xpath here from the root element)
          t.identifier(:path => "mods/mods:identifier", :namespace_prefix => MODS_NS_PREFIX)
          t.id_doi(:ref => :identifier, :attributes => {:type=>"doi"}, :namespace_prefix => MODS_NS_PREFIX)
          t.id_uri(:ref => :identifier, :attributes => {:type=>"uri"}, :namespace_prefix => MODS_NS_PREFIX)

          t.abstract(:path => "abstract", :namespace_prefix => MODS_NS_PREFIX)

          # This is a mods:name. The underscore is purely to avoid namespace conflicts.
          t.name_(:path => "name", :namespace_prefix => MODS_NS_PREFIX) {
            t.namePart(:type => :string)
            t.role(:ref => [:role])
            t.date(:path => "namePart", :attributes => {:type=>"date"}, :namespace_prefix => MODS_NS_PREFIX)
            t.last_name(:path => "namePart", :attributes => {:type=>"family"}, :namespace_prefix => MODS_NS_PREFIX)
            t.first_name(:path => "namePart", :attributes => {:type=>"given"}, :label => "first name", :namespace_prefix => MODS_NS_PREFIX)
          }
          # Role
          t.role(:path => "role", :namespace_prefix => MODS_NS_PREFIX) {
            t.text(:path => "roleTerm",:attributes=>{:type=>"text"}, :namespace_prefix => MODS_NS_PREFIX)
            t.code(:path => "roleTerm",:attributes=>{:type=>"code"}, :namespace_prefix => MODS_NS_PREFIX)
            t.authority(:path => {:attribute=> "authority"})
          }

          # Language
          t.language_any(:path => "language", :namespace_prefix => MODS_NS_PREFIX) {
            t.language_for(:path => {:attribute => "objectPart"})
            t.language_text(:path => "languageTerm",:attributes=>{:type=>"text"}, :namespace_prefix => MODS_NS_PREFIX)
            t.language_code(:path => "languageTerm",:attributes=>{:type=>"code"}, :namespace_prefix => MODS_NS_PREFIX)
          }

          # language specific to resource
          t.language_any_object_part(:path => "language[@objectPart]", :namespace_prefix => MODS_NS_PREFIX) {
            # When multiple language terms, to what resource the language applies can be specified
            # by using the @objectPart. Examples of its values: abstract, summary, note...
            t.language_for(:path => {:attribute => "objectPart"})
            t.language_text(:path => "languageTerm",:attributes=>{:type=>"text"}, :namespace_prefix => MODS_NS_PREFIX)
            t.language_code(:path => "languageTerm",:attributes=>{:type=>"code"}, :namespace_prefix => MODS_NS_PREFIX)
          }

          t.main_subject(:path => "subject", :namespace_prefix => MODS_NS_PREFIX) {
            t.main_topic(:path => "topic", :namespace_prefix => MODS_NS_PREFIX)
            t.name_topic(:ref => :name)
            # Temporal
            t.temporal(:path => "temporal", :namespace_prefix => MODS_NS_PREFIX) {
              t.temporal_lang(:path => {:attribute=> "lang"})
            }
            # Geographic
            t.geographic(:path => "geographic", :namespace_prefix => MODS_NS_PREFIX) {
              t.geographic_lang(:path => {:attribute=> "lang"})
            }
            # HierarchicalGeographic
            t.hierarchical_geographic(:path => "hierarchicalGeographic", :namespace_prefix => MODS_NS_PREFIX) {
              t.hierarchical_geographic_lang(:path => {:attribute=> "lang"})
            }
            # GeographicCode
            t.geographic_code(:path => "geographicCode", :namespace_prefix => MODS_NS_PREFIX) {
              t.geographic_code_lang(:path => {:attribute=> "lang"})
            }
            # Cartographics
            t.cartographics(:path => "cartographics", :namespace_prefix => MODS_NS_PREFIX) {
              t.coordinates(:namespace_prefix => MODS_NS_PREFIX)
              t.scale(:namespace_prefix => MODS_NS_PREFIX)
              t.projection(:namespace_prefix => MODS_NS_PREFIX)
            }
          }

          t.origin_info(:path => "originInfo", :namespace_prefix => MODS_NS_PREFIX) {
            t.date_created(:path => "dateCreated", :namespace_prefix => MODS_NS_PREFIX)
            t.date_captured(:path => "dateCaptured", :namespace_prefix => MODS_NS_PREFIX)
            t.date_issued(:path => "dateIssued", :namespace_prefix => MODS_NS_PREFIX)
            t.publisher(:namespace_prefix => MODS_NS_PREFIX)
            # Possible elements for source
            t.place(:path => "place", :namespace_prefix => MODS_NS_PREFIX) {
              t.place_term(:path => "placeTerm", :namespace_prefix => MODS_NS_PREFIX)
            }
            t.date_valid(:path => "dateValid", :namespace_prefix => MODS_NS_PREFIX)
            t.dat_emodified(:path => "dateModified", :namespace_prefix => MODS_NS_PREFIX)
            t.copyright_date(:path => "copyrightDate", :namespace_prefix => MODS_NS_PREFIX)
            t.date_other(:path => "dateOther", :namespace_prefix => MODS_NS_PREFIX)
            t.edition(:namespace_prefix => MODS_NS_PREFIX)
            t.issuance(:namespace_prefix => MODS_NS_PREFIX)
            t.frequency(:namespace_prefix => MODS_NS_PREFIX)
          }

          t.access_condition(:path => "accessCondition", :namespace_prefix => MODS_NS_PREFIX) {
            # It uses http://www.cdlib.org/inside/diglib/copyrightMD
            t.copyright(:path => "copyright", :namespace_prefix => CR_NS_PREFIX) {
              t.status_at(:path => {:attribute=>"copyright.status"})
              t.rights_holder(:path => "rights.holder", :namespace_prefix => CR_NS_PREFIX)
              t.general_note(:path => "general.note", :namespace_prefix => CR_NS_PREFIX)
            }
          }

          t.type_resource(:path => "typeOfResource", :attributes=>{:collection=>"yes"}, :namespace_prefix => MODS_NS_PREFIX)

          t.genre(:path => "genre", :namespace_prefix => MODS_NS_PREFIX) {
            t.type(:path => {:attribute => "type"})
          }

          t.physical_description(:path => "physicalDescription", :namespace_prefix => MODS_NS_PREFIX) {
            # The size of the collection
            t.extent(:namespace_prefix => MODS_NS_PREFIX)
            t.note_mods_type(:ref=>[:note_mods_type])
            t.note_mods_no_type(:ref=>[:note_mods_no_type])
          }
          # Related Item
          t.related_item(:path => "relatedItem", :namespace_prefix => MODS_NS_PREFIX) {
            t.identifier_(:path => "identifier", :attributes => {"type" => "uri"}, :namespace_prefix => MODS_NS_PREFIX)
            t.title_info(:ref => [:title_info])
            t.type_related_item(:ref => [:type_resource], :namespace_prefix => MODS_NS_PREFIX)
            t.genre_(:ref=> [:genre])
          }

          # tableOfContents
          t.table_contents(:path => "mods/mods:tableOfContents", :namespace_prefix => MODS_NS_PREFIX) {
            t.format_at(:path => {:attribute => "altFormat"})
            t.content_at(:path => {:attribute => "altContent"})
          }

          # Note
          t.note_mods_type(:path=>"mods/mods:note[@type]", :namespace_prefix => MODS_NS_PREFIX) {
            t.label_at(:path => {:attribute=> "displayLabel"})
            t.type_at(:path => {:attribute=> "type"})
          }

          t.note_mods_no_type(:path=>"mods/mods:note[not(@type)]", :namespace_prefix => MODS_NS_PREFIX) {
            t.label_at(:path => {:attribute=> "displayLabel"})
          }

          # ----------------------------------------------------------------------------------------------------------
          # Term proxies definition: must be absolute paths, avoid picking relatedItem elements

          # Title
          t.title(:proxy => [:mods, :title_info, :main_title], :index_as => [Descriptors.cleaned_searchable,
                                                                      Descriptors.cleaned_displayable])
          # Creator ()
          t.creator(:path => "mods/mods:name[mods:role/mods:roleTerm/@authority='marcrelator' and mods:role/mods:roleTerm/@type='code' and mods:role/mods:roleTerm = ('cre' or 'aut')]/mods:namePart",
                    :index_as=>[Descriptors.cleaned_facetable, Descriptors.cleaned_searchable,
                                Descriptors.cleaned_displayable,  :sortable],
                    :namespace_prefix => MODS_NS_PREFIX)
          # Contributor
          t.contributor(:path => "mods/mods:name[mods:role/mods:roleTerm/@authority='marcrelator' and mods:role/mods:roleTerm/@type='code' and mods:role/mods:roleTerm = 'ctb']/mods:namePart",
                        :index_as=>[Descriptors.cleaned_facetable, Descriptors.cleaned_searchable,
                                    Descriptors.cleaned_displayable,  :sortable],
                        :namespace_prefix => MODS_NS_PREFIX)
          # Description: abstract, tableOfContents, or note
          t.description(:path => "mods/mods:abstract", :index_as => [Descriptors.cleaned_searchable,
                                                           Descriptors.cleaned_displayable],
                        :namespace_prefix => MODS_NS_PREFIX)
          # Subject: defaults to subject/topic (relative path any subject)
          t.subject_(:path => "subject/mods:topic", :index_as=>[Descriptors.cleaned_searchable,
                                                           Descriptors.cleaned_facetable,
                                                           Descriptors.cleaned_displayable],
                     :namespace_prefix => MODS_NS_PREFIX)
          # language
          t.language(:proxy => [:language_any, :language_code], :index_as=>[Descriptors.cleaned_searchable,
                                                                              Descriptors.language_facetable])

          # Source
          # TODO - decide the preference: place for location, dates for temporal
          t.source(:path => "mods/mods:originInfo/mods:place/mods:placeTerm", :index_as=>[Descriptors.cleaned_displayable,
                                                                      Descriptors.cleaned_facetable],
                   :namespace_prefix => MODS_NS_PREFIX)
          # Type
          t.type(:proxy => [:mods, :type_resource], :index_as=>[Descriptors.cleaned_facetable,
                                                         Descriptors.cleaned_searchable,
                                                         Descriptors.cleaned_displayable],
                 :namespace_prefix => MODS_NS_PREFIX)

          # Rights - needs special indexing
          t.rights(:path => "mods/mods:accessCondition", :index_as=>[Descriptors.cleaned_searchable,
                                                           Descriptors.cleaned_displayable],
                   :namespace_prefix => MODS_NS_PREFIX)
          # Publisher
          t.publisher(:path => "mods/mods:originInfo/mods:publisher", :index_as => [Descriptors.cleaned_facetable,
                                                                     Descriptors.cleaned_searchable,
                                                                     Descriptors.cleaned_displayable],
                      :namespace_prefix => MODS_NS_PREFIX)
          # Published_date
          t.published_date(:path => "mods/mods:originInfo/mods:dateIssued", :index_as=>[Descriptors.cleaned_searchable,
                                                                         Descriptors.cleaned_displayable],
                           :namespace_prefix => MODS_NS_PREFIX)
          # Creation_date
          t.creation_date(:path => "mods/mods:originInfo/mods:dateCreated", :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable],
                          :namespace_prefix => MODS_NS_PREFIX)

          t.creation_date_start(:path => "mods/mods:originInfo/mods:dateCreated", :attributes=>{:point=>"start"},
                                :namespace_prefix => MODS_NS_PREFIX) {
            t.encoding_at(:path => {:attribute => "encoding"})
          }

          t.creation_date_end(:path => "mods/mods:originInfo/mods:dateCreated", :attributes=>{:point=>"end"},
                                :namespace_prefix => MODS_NS_PREFIX) {
            t.encoding_at(:path => {:attribute => "encoding"})
          }

          # Coverage
          # temporal_coverage
          t.temporal_coverage(:path => "subject/mods:temporal", :index_as=>[Descriptors.cleaned_searchable,
                                                                       Descriptors.cleaned_facetable,
                                                                       Descriptors.cleaned_displayable],
                              :namespace_prefix => MODS_NS_PREFIX)
          t.temporal_coverage_lang(:path => "subject/mods:temporal/@lang")

          # geographical_coverage
          t.geographical_coverage(:path => "subject/mods:geographic", :index_as=>[Descriptors.cleaned_searchable,
                                                                             Descriptors.cleaned_facetable,
                                                                             Descriptors.cleaned_displayable],
                                  :namespace_prefix => MODS_NS_PREFIX)
          t.geographical_coverage_lang(:path => "subject/mods:geographic/@lang")

          # Roles proxy, similar to QDC
          DRI::Vocabulary::marcRelators.each do |role|
            t.send "role_" + role, :path=>"name[mods:role/mods:roleTerm/@authority='marcrelator' and mods:role/mods:roleTerm/@type='code' and mods:role/mods:roleTerm = \'#{role}\']/mods:namePart",
                   :index_as=>[Descriptors.cleaned_facetable, Descriptors.cleaned_searchable,
                               Descriptors.cleaned_displayable], :namespace_prefix => MODS_NS_PREFIX
          end

          # Relationships
          DRI::Vocabulary::modsRelationshipTypes.each do |rel|
            t.send "related_items_ids_" + rel,
                   :path=>"relatedItem[@type='#{rel}']/mods:identifier[@type='local']",
                   :namespace_prefix => MODS_NS_PREFIX
          end

          # MODS Terms
          t.mods_id_local(:path => "/mods:mods/mods:identifier[@type='local']", :index_as => [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])

          t.mods_type_collection(:proxy => [:mods, :type_resource])

          t.subtitle(:proxy => [:title_info, :subtitle], :index_as => [Descriptors.cleaned_searchable,
                                                                       Descriptors.cleaned_displayable])
          t.abstract(:path => "mods/mods:abstract", :index_as => [Descriptors.cleaned_searchable,
                                                        Descriptors.cleaned_displayable],
                     :namespace_prefix => MODS_NS_PREFIX)
          t.toc_(:ref => :table_contents, :index_as => [Descriptors.cleaned_searchable,
                                                       Descriptors.cleaned_displayable])

          # TODO - Check about @type for note - http://www.loc.gov/standards/mods/mods-notes.html
          #t.note(:path => "mods/mods:note", :namespace_prefix => MODS_NS_PREFIX)

          # Subject name
          t.name_coverage(:proxy => [:main_subject, :name_topic])

          # Subject: temporal, date
          t.subject_temporal(:path => "subject/mods:temporal", :namespace_prefix => MODS_NS_PREFIX)
          t.subject_date_start(:path => "subject/mods:temporal", :attributes=>{:point=>"start"},
                               :namespace_prefix => MODS_NS_PREFIX) {
            t.encoding_at(:path => {:attribute => "encoding"})
          }
          t.subject_date_end(:path => "subject/mods:temporal", :attributes=>{:point=>"end"},
                             :namespace_prefix => MODS_NS_PREFIX) {
            t.encoding_at(:path => {:attribute => "encoding"})
          }
          t.date(:proxy => [:name, :date])
          t.date_captured(:proxy => [:origin_info, :date_captured])
          t.date_other(:proxy => [:origin_info, :date_other])

          # Other mappings to geographical/temporal
          t.hierarchical_geographic(:path => "subject/mods:hierarchicalGeographic", :namespace_prefix => MODS_NS_PREFIX)
          t.hierarchical_geographic_lang(:path => "subject/mods:hierarchicalGeographic/@lang")

          t.cartographics_scale(:path => "subject/mods:cartographics/mods:scale",
                                :namespace_prefix => MODS_NS_PREFIX)
          t.cartographics_coordinates(:path => "subject/mods:cartographics/mods:coordinates",
                                      :namespace_prefix => MODS_NS_PREFIX)
          t.cartographics_projection(:path => "subject/mods:cartographics/mods:projection",
                                     :namespace_prefix => MODS_NS_PREFIX)

          t.geographic_code(:proxy => [:main_subject, :geographic_code])

          # language, specific to a terms of the MODS record: e.g. language for abstract
          t.language_object_part(:ref => [:language_any_object_part])

        end # End set terminology
      end

      # TODO - Override OM method
      def to_solr(solr_doc=Hash.new, opts = {})
        solr_doc = super(solr_doc)


        # Title_sorted - A SOLR index for sorting titles
        if (title.length > 0)

          sorted_title = DRI::Metadata::Transformations.transform_title_for_sort(title[0])

          if (sorted_title != "")
            solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('title_sorted', :stored_sortable, type: :string) => [sorted_title])
          end
        end

        # Type
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('type', :stored_searchable) => type)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('type', :facetable) => type)

        # EAD has several "name" tags, so we merge them together into the SOLR document
        person_array = person_array_for_index()

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('person', :facetable) => person_array)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('person', :stored_searchable, type: :text) => person_array | DRI::Metadata::Transformations.transform_name(person_array))

        # all_metadata - A SOLR index of all the text contained in the XML document
        all_metadata = ""
        ng_xml.xpath("//text()").each do |text_node|
          all_metadata += text_node.text
          all_metadata += " "
        end
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name("all_metadata", :stored_searchable, type: :text) => [all_metadata])

        # Description
        description_array = description_for_index()

        solr_doc.merge!(ActiveFedora::SolrService.solr_name('description', :stored_searchable, type: :string) => description_array)

        # Subject
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('subject', :stored_searchable) => subject) unless subject == []
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('subject', :facetable) => subject) unless subject == []

        subject_name_array = subject_name_for_index()
        subject_place_array = subject_place_for_index()
        subject_temporal_array = subject_temporal_for_index()

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('name_coverage', :stored_searchable) => subject_name_array) unless subject_name_array == []
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('name_coverage', :facetable) => subject_name_array) unless subject_name_array == []

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('geographical_coverage', :stored_searchable) => subject_place_array) unless subject_place_array == []
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('geographical_coverage', :facetable) => subject_place_array) unless subject_place_array == []

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('temporal_coverage', :stored_searchable) => subject_temporal_array) unless subject_temporal_array == []
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('temporal_coverage', :facetable) => subject_temporal_array) unless subject_temporal_array == []

        # Published Date
        #solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('published_date', :stored_searchable) => published_date) unless published_date == []

        # Publisher
        #solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('publisher', :stored_searchable) => publisher) unless publisher == []

        # Type
        solr_doc.merge!(ActiveFedora::SolrService.solr_name('type', :stored_searchable, type: :string) => "Collection")

        solr_doc
      end

      # Indexing Methods
      # --------------------------------------------------------------------------------------------------------------
      def description_for_index
        return abstract if !abstract.empty?
        return toc if !toc.empty?
        unless (note_mods_type.empty? && note_mods_no_type.empty?)
          note_formatted = note_mods_type.collect!.with_index do |name, idx|
            name = "#{name} [#{note_mods_type.type_at[idx]}]"
          end
          return note_formatted | note_mods_no_type
        end

        return []
      end

      def person_array_for_index()
        return creator | contributor
      end

      # These are DRI Subject(Name)
      def subject_name_for_index()
        return name_coverage
      end

      # These are DRI Subject(Place)
      def subject_place_for_index()
        return geographical_coverage | hierarchical_geographic | cartographics_scale | cartographics_coordinates |
            cartographics_projection | geographic_code
      end

      # These are DRI Subject(Place)
      def subject_temporal_for_index()
        # Extract temporal ranges
        dates_range_array = subject_date_start.collect!.with_index do |name, idx|
          name = (idx <= (subject_date_end.length - 1)) ? ("#{name} - #{subject_date_end[idx]}") : name
        end

        return temporal_coverage | dates_range_array | date
      end

      # --------------------------------------------------------------------------------------------------------------

      def metadata_path field
        recognised_attributes = [:title, :rights, :description, :language, :subject, :contributor,
                                  :source, :publisher, :creator, :type, :identifier, :published_date, :creation_date,
                                  :geographical_coverage, :geographical_coverage_lang, :temporal_coverage,
                                  :temporal_coverage_lang]
        if recognised_attributes.include? field
          [field]
        elsif m = /^role_(.*)/.match(field.to_s)
          if DRI::Vocabulary::marcRelators.include? m[1]
            [field]
          else
            []
          end
        else
          []
        end
      end

      def roles= roles
        if roles.is_a? Hash
          if roles.has_key?("type") && roles.has_key?("name") && (roles["type"].size == roles["name"].size )
            changed_roles = Hash.new
            roles["type"].uniq.each do |role|
              changed_roles[role] = []
            end

            roles["type"].each_with_index do |role, i|
              if (roles["name"][i] != "")
                changed_roles[role].push(roles["name"][i])
              end
            end

            changed_roles.keys.each do |role|
              send role+"=", changed_roles[role]
            end
          end
        end
      end

      def update_indexed_attributes(params={}, opts={})
        # if the params are just keys, not an array, make then into an array.
        new_params = {}
        params.each do |key, val|
          if key.is_a? Array
            new_params[key] = val
          else
            new_params[[key.to_sym]] = val
          end
        end
        super(new_params, opts)
      end

      # Build the xml doc
      def self.xml_template
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.mods(:version => "3.5", "xmlns:#{MODS_NS_PREFIX}" => MODS_NS,
                   "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
                   "xmlns:xlink" => "http://www.w3.org/1999/xlink",
                   "xmlns:marcrel" => "http://www.loc.gov/marc.relators/",
                   "xmlns:dcterms" => "http://purl.org/dc/terms/",
                   "xmlns:#{CR_NS_PREFIX}" => CR_NS,
                   "xsi:schemaLocation" => MODS_SCHEMA) {
            xml['mods'].titleInfo.title
            xml['mods'].abstract
            xml['mods'].typeOfResource("collection" => "yes"){xml.text("mixed materials")}
            xml['mods'].genre("type" => "dct"){xml.text("Collection")}
          }
        end
        return builder.doc
      end

      # FIXME This is probably not needed anymore
      def synchronize_metadata_on_save
        false
      end
      # FIXME This is probably not needed anymore
      def interchangeable?
        false
      end

      def collection?
        true
      end

      def custom_validations
        errors = Hash.new
        identifier_result = true
        uri_result = true
        #rel_item_ids_result = true
        title_result = false
        description_result = false
        rights_result = false
        type_result = false
        date_result = false
        type_collection = false

        # This is the mods identifier used internally in DRI: uniquely identify a record/relationships management
        if (mods_id_local.size == 1 && mods_id_local.first == "")
          identifier_result = false
        end

        id_uri.each do |uri_r|
          uri_result = false unless (!uri_r.blank? && Utils.valid_uri?(uri_r))
        end

        title.each do |curr_title|
          title_result = true unless curr_title.blank?
        end

        description_for_index().each do |curr_description|
          description_result = true unless curr_description.blank?
        end

        rights.each do |curr_right|
          rights_result = true unless curr_right.blank?
        end

        type.each do |curr_type|
          type_result = true unless curr_type.blank?
        end

        creation_date.each do |curr_date|
          date_result = true unless curr_date.blank?
        end

        mods_type_collection.each do |type_value|
          type_collection = true unless type_value.nil?
        end

        errors[:mods_id_local] = "not present." unless identifier_result == true
        errors[:mods_type_collection] = "not present" unless type_collection == true
        errors[:id_uri] = "Invalid URI present" unless id_uri.empty? || uri_result == true
        errors[:title] = "can't be blank" if title_result == false
        errors[:description] = "can't be blank" if description_result == false
        errors[:rights] = "can't be blank" if rights_result == false
        errors[:type] = "can't be blank" if type_result == false
        errors[:creation_date] = "can't be blank" if date_result == false

        return errors
      end

      # Load terminology
      load_inherited_terminology
    end # class

  end # module

end # module
