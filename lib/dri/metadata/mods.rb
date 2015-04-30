module DRI

  module Metadata

    # An ActiveFedora datastream that interacts with MODS.

    class Mods < DRI::Metadata::Base

      # MODS XML constants.
      MODS_NS_PREFIX = "mods"
      MODS_NS = 'http://www.loc.gov/mods/v3'
      MODS_SCHEMA = 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-5.xsd'
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
          # Map to the mods record identifier (absolute xpath here)
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

          t.type_resource(:path => "typeOfResource", :namespace_prefix => MODS_NS_PREFIX){
            t.collection_at(:path => {:attribute=>"collection"})
          }

          t.genre(:path => "genre", :namespace_prefix => MODS_NS_PREFIX)

          t.physical_description(:path => "physicalDescription", :namespace_prefix => MODS_NS_PREFIX) {
            t.form(:namespace_prefix => MODS_NS_PREFIX)
            t.reformatting_quality(:path => "reformattingQuality", :namespace_prefix => MODS_NS_PREFIX)
            t.internet_media(:path => "internetMediaType", :namespace_prefix => MODS_NS_PREFIX)
            t.extent(:namespace_prefix => MODS_NS_PREFIX)
            t.digital_origin(:path=>"digitalOrigin", :namespace_prefix => MODS_NS_PREFIX)
            t.note_mods_no_type(:ref=>[:note_mods_no_type])
            t.note_mods_type(:ref=>[:note_mods_type])
          }

          # location
          t.location(:path => "location", :namespace_prefix => MODS_NS_PREFIX) {
            t.physical_location(:namespace_prefix => MODS_NS_PREFIX)
            t.shelf_locator(:path => "shelfLocator", :namespace_prefix => MODS_NS_PREFIX)
            t.url(:namespace_prefix => MODS_NS_PREFIX)
            t.holding_simple(:path => "holdingSimple", :namespace_prefix => MODS_NS_PREFIX)
            t.holding_external(:path => "holdingExternal", :namespace_prefix => MODS_NS_PREFIX)
          }

          # tableOfContents
          t.table_contents(:path => "tableOfContents", :namespace_prefix => MODS_NS_PREFIX) {
            t.format_at(:path => {:attribute => "altFormat"})
            t.content_at(:path => {:attribute => "altContent"})
          }

          # classification
          t.classification(:namespace_prefix => MODS_NS_PREFIX)

          # part
          t.part(:path => "part", :namespace_prefix => MODS_NS_PREFIX) {
            t.detail(:namespace_prefix => MODS_NS_PREFIX)
            t.extent(:namespace_prefix => MODS_NS_PREFIX)
            t.date_part(:path => "date", :namespace_prefix => MODS_NS_PREFIX)
            t.text(:namespace_prefix => MODS_NS_PREFIX)
          }

          #t.date(:path => "date", :namespace_prefix => MODS_NS_PREFIX) {
          #  t.encoding_at(:path => {:attribute => "encoding"})
          #  t.point_at(:path => {:attribute => "point"})
          #}

          # recordInfo
          t.record_info(:path => "recordInfo", :namespace_prefix => MODS_NS_PREFIX) {

          }

          t.target_audience(:path => "targetAudience", :namespace_prefix => MODS_NS_PREFIX) {
            t.recordContentSource(:namespace_prefix => MODS_NS_PREFIX)
            t.recordCreationDate(:namespace_prefix => MODS_NS_PREFIX)
            t.recordChangeDate(:namespace_prefix => MODS_NS_PREFIX)
            t.recordIdentifier(:namespace_prefix => MODS_NS_PREFIX)
            t.recordOrigin(:namespace_prefix => MODS_NS_PREFIX)
            t.lang_of_cataloging(:ref => [:lang_of_cataloging])
            t.descriptionStandard(:namespace_prefix => MODS_NS_PREFIX)
          }

          t.lang_of_cataloging(:path => "languageOfCataloging", :namespace_prefix => MODS_NS_PREFIX) {
            t.language_text(:path => "languageTerm",:attributes=>{:type=>"text"}, :namespace_prefix => MODS_NS_PREFIX)
            t.language_code(:path => "languageTerm",:attributes=>{:type=>"code"}, :namespace_prefix => MODS_NS_PREFIX)
            t.script_term_text(:path => "scriptTerm",:attributes=>{:type=>"text"}, :namespace_prefix => MODS_NS_PREFIX)
            t.script_term_code(:path => "scriptTerm",:attributes=>{:type=>"code"}, :namespace_prefix => MODS_NS_PREFIX)
          }

          # Note
          t.note_mods_type(:path=>"mods/mods:note[@type]", :namespace_prefix => MODS_NS_PREFIX) {
            t.label_at(:path => {:attribute=> "displayLabel"})
            t.type_at(:path => {:attribute=> "type"})
          }

          t.note_mods_no_type(:path=>"mods/mods:note[not(@type)]", :namespace_prefix => MODS_NS_PREFIX) {
            t.label_at(:path => {:attribute=> "displayLabel"})
          }

          # Related Item
          t.related_item(:path => "relatedItem", :namespace_prefix => MODS_NS_PREFIX) {
            t.identifier_(:path => "identifier", :namespace_prefix => MODS_NS_PREFIX)
            t.title_info(:ref => [:title_info])
            t.name_(:ref => [:name])
            t.type_resource_item(:ref => [:type_resource])
            t.genre(:ref=> [:genre])
            t.originInfo(:ref => [:origin_info])
            t.language(:ref => [:language])
            t.physical_description(:ref => [:physical_description])
            t.abstract(:ref => [:abstract])
            t.rel_toc(:ref => :table_contents)
            t.targetAudience(:ref => [:target_audience])
            t.note_mods_no_type(:ref => [:note_mods_no_type])
            t.note_mods_type(:ref => [:note_mods_type])
            t.subject(:ref => [:subject])
            t.classification(:namespace_prefix => MODS_NS_PREFIX)
            t.location(:ref => [:location])
            t.access_condition(:ref => [:access_condition])
            t.part(:ref => [:part])
            t.extension(:namespace_prefix => MODS_NS_PREFIX)
            t.recordInfo(:ref => [:record_info])
          }

          # ----------------------------------------------------------------------------------------------------------
          # Term proxies definition: must be absolute paths, avoid picking relatedItem elements

          # Title
          t.title(:proxy => [:mods, :title_info, :main_title], :index_as => [Descriptors.cleaned_searchable,
                                                               Descriptors.cleaned_displayable])
          # Creator
          t.creator(:path => "mods/mods:name[mods:role/mods:roleTerm/@authority='marcrelator' and mods:role/mods:roleTerm/@type='code' and (mods:role/mods:roleTerm[@type='code' and @authority='marcrelator'] = 'cre' or mods:role/mods:roleTerm[@type='code' and @authority='marcrelator'] = 'aut' or mods:role/mods:roleTerm[@type='code' and @authority='marcrelator'] = 'art' or mods:role/mods:roleTerm[@type='code' and @authority='marcrelator'] = 'att')]/mods:namePart",
                    :index_as=>[Descriptors.cleaned_facetable, Descriptors.cleaned_searchable,
                                                   Descriptors.cleaned_displayable,  :sortable],
                    :namespace_prefix => MODS_NS_PREFIX)
          # Contributor
          t.contributor(:path => "mods/mods:name[mods:role/mods:roleTerm/@authority='marcrelator' and (mods:role/mods:roleTerm = 'ctb' or mods:role/mods:roleTerm[@type='code' and @authority='marcrelator'] = 'rcp' or mods:role/mods:roleTerm[@type='code' and @authority='marcrelator'] = 'pat')]/mods:namePart",
                        :index_as=>[Descriptors.cleaned_facetable, Descriptors.cleaned_searchable,
                                    Descriptors.cleaned_displayable,  :sortable],
                        :namespace_prefix => MODS_NS_PREFIX)
          # Description: abstract, tableOfContents, or note
          # TODO Check this XPath
          t.description(:path => "//mods:mods/mods:abstract | //mods:mods[not(mods:abstract)]/mods:note | //mods:mods[not(mods:abstract) and not(mods:note)]/mods:tableOfContents | //mods:mods[not(mods:abstract) and not(mods:note) and not(mods:tableOfContents)]/mods:physicalDescription/mods:note", :index_as => [Descriptors.cleaned_searchable,
                                                           Descriptors.cleaned_displayable])
          # Subject: defaults to subject/topic
          t.subject_(:path => "mods/mods:subject/mods:topic", :index_as=>[Descriptors.cleaned_searchable,
                                                            Descriptors.cleaned_facetable,
                                                            Descriptors.cleaned_displayable],
                     :namespace_prefix => MODS_NS_PREFIX)

          # language
          t.language(:path => "language/mods:languageTerm[@type='code']", :index_as=>[Descriptors.cleaned_searchable,
                                                                           Descriptors.language_facetable])

          # Source
          t.source(:path => "mods/mods:relatedItem[@type='original']/mods:location/mods:physicalLocation | mods/mods:relatedItem[@type='original' and not(mods:location)]/mods:titleInfo/mods:title", :index_as=>[Descriptors.cleaned_displayable,
                                                                 Descriptors.cleaned_facetable],
                   :namespace_prefix => MODS_NS_PREFIX)
          # Type
          t.type(:path => "mods/mods:typeOfResource", :index_as=>[Descriptors.cleaned_facetable,
                                           Descriptors.cleaned_searchable,
                                           Descriptors.cleaned_displayable],
                 :namespace_prefix => MODS_NS_PREFIX)

          t.mods_type_collection(:path => "mods/mods:typeOfResource[@collection='yes']", :namespace_prefix => MODS_NS_PREFIX)

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
          t.published_date(:path => "mods/mods:originInfo/mods:dateIssued", :attributes => {"point" => :none},
                           :namespace_prefix => MODS_NS_PREFIX)

          # Issued (Published) date ranges
          t.issued_date_start(:path => "mods/mods:originInfo/mods:dateIssued[@encoding='w3cdtf' or @encoding='iso8601']", :attributes=>{:point=>"start"},
                              :namespace_prefix => MODS_NS_PREFIX)
          t.issued_date_end(:path => "mods/mods:originInfo/mods:dateIssued[@encoding='w3cdtf' or @encoding='iso8601']", :attributes=>{:point=>"end"},
                            :namespace_prefix => MODS_NS_PREFIX)

          # Creation_date
          t.creation_date(:path => "//mods:mods/mods:originInfo/mods:dateCreated[not(@point)] | //mods:mods/mods:originInfo[not(mods:dateCreated)]/mods:dateIssued[not(@point)] | //mods:mods/mods:originInfo[not(mods:dateCreated) and not(mods:dateIssued)]/mods:dateCaptured[not(@point)]")
          # Creation date ranges
          t.creation_date_start(:path => "mods/mods:originInfo/mods:dateCreated[@encoding='w3cdtf' or @encoding='iso8601']", :attributes=>{:point=>"start"},
                                :namespace_prefix => MODS_NS_PREFIX)
          t.creation_date_end(:path => "mods/mods:originInfo/mods:dateCreated[@encoding='w3cdtf' or @encoding='iso8601']", :attributes=>{:point=>"end"},
                              :namespace_prefix => MODS_NS_PREFIX)

          # Coverage
          # temporal_coverage
          t.temporal_coverage(:path => "subject/mods:temporal[not(@point)]", :namespace_prefix => MODS_NS_PREFIX)

          t.temporal_coverage_lang(:path => "subject/mods:temporal/@lang")

          # geographical_coverage
          t.geographical_coverage(:path => "subject/mods:geographic", :namespace_prefix => MODS_NS_PREFIX,
                                  :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable,
                                              Descriptors.cleaned_displayable])
          t.geographical_coverage_lang(:path => "subject/mods:geographic/@lang")

          t.geographic_code(:proxy => [:main_subject, :geographic_code])

          # Roles proxy, similar to QDC
          DRI::Vocabulary::marcRelators.each do |role|
            t.send "role_" + role, :path=>"name[mods:role/mods:roleTerm/@authority='marcrelator' and mods:role/mods:roleTerm/@type='code' and mods:role/mods:roleTerm = \'#{role}\' and (mods:role/mods:roleTerm[@type='code' and @authority='marcrelator'] != 'cre' and mods:role/mods:roleTerm[@type='code' and @authority='marcrelator'] != 'aut' and mods:role/mods:roleTerm[@type='code' and @authority='marcrelator'] != 'art' and mods:role/mods:roleTerm[@type='code' and @authority='marcrelator'] != 'ctb' and mods:role/mods:roleTerm[@type='code' and @authority='marcrelator'] != 'rcp' and mods:role/mods:roleTerm[@type='code' and @authority='marcrelator'] != 'pat' and mods:role/mods:roleTerm[@type='code' and @authority='marcrelator'] != 'att')]/mods:namePart[not(@type='date')]",
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
          t.mods_id_local(:path => "mods:mods/mods:identifier[@type='local']", :index_as => [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
          # mods_id_asset - Used for sorting sequenced items
          t.mods_id_asset(:path => "mods:mods/mods:identifier[@type='asset']", :index_as => [:stored_sortable])

          t.subtitle(:proxy => [:title_info, :subtitle], :index_as => [Descriptors.cleaned_searchable,
                                                                       Descriptors.cleaned_displayable])
          t.abstract(:path => "abstract", :index_as => [Descriptors.cleaned_searchable,
                                                      Descriptors.cleaned_displayable],
                     :namespace_prefix => MODS_NS_PREFIX)
          t.toc_(:ref => :table_contents, :index_as => [Descriptors.cleaned_searchable,
                                                           Descriptors.cleaned_displayable])

          # TODO - Check about @type for note - http://www.loc.gov/standards/mods/mods-notes.html
          #t.note(:ref => [:note_mods], :namespace_prefix => MODS_NS_PREFIX)

          # Subject name
          t.name_coverage(:proxy => [:main_subject, :name_topic])

          # Other mappings to geographical/temporal
          t.hierarchical_geographic(:path => "subject/mods:hierarchicalGeographic", :namespace_prefix => MODS_NS_PREFIX)
          t.hierarchical_geographic_lang(:path => "subject/mods:hierarchicalGeographic/@lang")
          t.cartographics_scale(:path => "subject/mods:cartographics/mods:scale", :namespace_prefix => MODS_NS_PREFIX)
          t.cartographics_coordinates(:path => "subject/mods:cartographics/mods:coordinates", :namespace_prefix => MODS_NS_PREFIX)
          t.cartographics_projection(:path => "subject/mods:cartographics/mods:projection", :namespace_prefix => MODS_NS_PREFIX)

          # language, specific to a terms of the MODS record: e.g. language for abstract
          t.language_object_part(:ref => [:language_any_object_part])

          # Add TERMS for External relationships
          t.related_items_digital(:path => "//mods:mods/mods:relatedItem/mods:location/mods:url | //mods:mods/mods:location/mods:url")

          # //relatedItem[@type='*' and not(mods:identifier[@type='local'])]
          DRI::Vocabulary::modsRelationshipTypes.each do |rel|
            t.send "ext_related_items_ids_" + rel,
                   :path => "relatedItem[@type='#{rel}']/mods:location/mods:url | relatedItem[@type='#{rel}']/mods:location/mods:physicalLocation",
                   :namespace_prefix => MODS_NS_PREFIX
          end

          # Proxies definition for temporal elements

          # Subject: temporal, date range (@point attribute)
          t.subject_date_start(:path => "subject/mods:temporal[@encoding='w3cdtf' or @encoding='iso8601']", :attributes=>{:point=>"start"},
                               :namespace_prefix => MODS_NS_PREFIX)
          t.subject_date_end(:path => "subject/mods:temporal[@encoding='w3cdtf' or @encoding='iso8601']", :attributes=>{:point=>"end"},
                             :namespace_prefix => MODS_NS_PREFIX)
          t.date(:path => "name/mods:namePart[@type='date']", :namespace_prefix => MODS_NS_PREFIX)

          t.captured_date(:path => "mods/mods:originInfo/mods:dateCaptured[not(@point)]", :namespace_prefix => MODS_NS_PREFIX)
          # Captured date ranges
          t.captured_date_start(:path => "mods/mods:originInfo/mods:dateCaptured[@encoding='w3cdtf' or @encoding='iso8601']", :attributes=>{:point=>"start"},
                                :namespace_prefix => MODS_NS_PREFIX)
          t.captured_date_end(:path => "mods/mods:originInfo/mods:dateCaptured[@encoding='w3cdtf' or @encoding='iso8601']", :attributes=>{:point=>"end"},
                              :namespace_prefix => MODS_NS_PREFIX)
          t.date_other(:proxy => [:origin_info, :date_other], :attributes => {"point" => :none})
          t.date_other_start(:path => "mods/mods:originInfo/mods:dateOther[@encoding='w3cdtf' or @encoding='iso8601']", :attributes=>{:point=>"start"},
                                :namespace_prefix => MODS_NS_PREFIX)
          t.date_other_end(:path => "mods/mods:originInfo/mods:dateOther[@encoding='w3cdtf' or @encoding='iso8601']", :attributes=>{:point=>"end"},
                              :namespace_prefix => MODS_NS_PREFIX)
          t.part_date(:path => "part/mods:date[not(@point)]", :attributes => {"point" => :none}, :namespace_prefix => MODS_NS_PREFIX)
          t.part_date_start(:path => "part/mods:date[@encoding='w3cdtf' or @encoding='iso8601']", :attributes=>{:point=>"start"},
                                :namespace_prefix => MODS_NS_PREFIX)
          t.part_date_end(:path => "part/mods:date[@encoding='w3cdtf' or @encoding='iso8601']", :attributes=>{:point=>"end"},
                              :namespace_prefix => MODS_NS_PREFIX)
        end

      end
      # FIXME This is probably not needed anymore
      def synchronize_metadata_on_save
        false
      end
      # FIXME This is probably not needed anymore
      def interchangeable?
        false
      end

      # If the /mods/mods:typeOfResource[@collection="yes"] return true
      def collection?
        (!mods_type_collection.nil? && !mods_type_collection.empty?) ? true : false
      end

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

      #
      #
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

      #
      #
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

      # Build the xml doc
      def self.xml_template
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.mods(:version => "3.5", "xmlns:xlink" => "http://www.w3.org/1999/xlink",
                   "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
                   "xmlns:mods" => MODS_NS,
                   "xmlns:marcrel" => "http://www.loc.gov/marc.relators/",
                   "xmlns:dcterms" => "http://purl.org/dc/terms/",
                   "xmlns:#{CR_NS_PREFIX}" => CR_NS,
                   "xsi:schemaLocation" => MODS_SCHEMA) {
          }
        end
        return builder.doc
      end

      # Overriden. Solr indexing of custom fields
      # @param[SolrDocument] solr_doc the Solr document to be merged
      #
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

        # MODS has several "name" tags, so we merge them together into the SOLR document
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
        #description_array = description_for_index()

        #solr_doc.merge!(ActiveFedora::SolrService.solr_name('description', :stored_searchable, type: :string) => description_array)

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

        # Indices for external relationships (to be displayed as URL)
        external_rels = *(DRI::Vocabulary::modsRelationshipTypes.map { |s| s.prepend("ext_related_items_ids_").to_sym})

        external_rels.each do |elem|
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name(elem, :stored_searchable) => self.send(elem)) unless self.send(elem) == []
        end

        # Type
        if collection?
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('type', :stored_searchable, type: :string) => "Collection")
        end

        # Index creation_date
        creation_date_idx = creation_date_for_index()
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('creation_date', :stored_searchable) => creation_date_idx)

        # Index Published Date
        unless published_date == [] && issued_date_start == []
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('published_date', :stored_searchable) => display_single_date_for_index(published_date) |
          display_date_range_for_index(issued_date_start, issued_date_end))
        end

        # Index date ranges
        date_ranges = date_ranges_for_index() # ALL the date ranges

        # Creation date dateRange index
        cdate_ranges = date_ranges.select {|key, value| ["creation_date", "captured_date"].include?(key)}
        solr_doc.merge!(Transformations::CREATION_DATE_RANGE_SOLR_FIELD => DRI::Metadata::Transformations::transform_date_ranges(cdate_ranges)) unless cdate_ranges == {}

        # Published date dateRange index
        pdate_ranges = date_ranges.select {|key, value| ["issued_date"].include?(key)}
        solr_doc.merge!(Transformations::PUBLISHED_DATE_RANGE_SOLR_FIELD => DRI::Metadata::Transformations::transform_date_ranges(pdate_ranges)) unless pdate_ranges == {}

        # Subject date dateRange index
        sdate_ranges = date_ranges.select {|key, value| ["subject_date", "date_other", "part_date"].include?(key)}
        solr_doc.merge!(Transformations::SUBJECT_DATE_RANGE_SOLR_FIELD => DRI::Metadata::Transformations::transform_date_ranges(sdate_ranges)) unless sdate_ranges == {}

        solr_doc
      end

      # Indexing Methods
      # --------------------------------------------------------------------------------------------------------------
      # description_for_index NOT NEEDED as indexed in the terminology
      #def description_for_index
      #  return abstract if !abstract.empty?
      #  return toc if !toc.empty?
      #  unless (note_mods_type.empty? && note_mods_no_type.empty?)
      #    note_formatted = note_mods_type.collect!.with_index do |name, idx|
      #      name = "#{name} [#{note_mods_type.type_at[idx]}]"
      #    end
      #    return note_formatted | note_mods_no_type
      #  end
      #
      #  return []
      #end

      def creation_date_for_index()
        return display_single_date_for_index(creation_date) unless creation_date == []
        # Cases below needed as creation_date not only holds single dates and there are 3 possible fields for this date
        return display_date_range_for_index(creation_date_start, creation_date_end) unless creation_date_start == []
        return display_date_range_for_index(issued_date_start, issued_date_end) unless issued_date_start == []
        return display_date_range_for_index(captured_date_start, captured_date_end) unless captured_date_start == []

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
        return display_single_date_for_index(temporal_coverage) |
            display_single_date_for_index(date_other) |
            display_single_date_for_index(part_date) |
            display_date_range_for_index(subject_date_start, subject_date_end) |
            display_date_range_for_index(date_other_start, date_other_end) |
            display_date_range_for_index(part_date_start, part_date_end)
      end

      # No date ranges here, single date display (just the year)
      def display_single_date_for_index(date_field=[])
        date_field.collect! do| value |
          begin
            display_date = ISO8601::DateTime.new(value).strftime("%b %d, %Y")
            DRI::Metadata::Transformations.create_dcmi_period(display_date, value)
          rescue ISO8601::Errors::StandardError
            DRI::Metadata::Transformations.create_dcmi_period(value) # DCMI Period 'name' is the md value
          end
        end
      end

      # Display of date ranges: start_year - end_year
      def display_date_range_for_index(date_start=[], date_end=[])
        date_range_display = date_start.collect!.with_index do |name, idx|
          begin
            d_start = ISO8601::DateTime.new(name).strftime("%b %d, %Y")

            if idx <= (date_end.length - 1)
              d_end = ISO8601::DateTime.new(date_end[idx]).strftime("%b %d, %Y")
              DRI::Metadata::Transformations.create_dcmi_period(d_start << " - " << d_end, name, date_end[idx])
            else
              Transformations.create_dcmi_period(d_start, name)
            end
          rescue ISO8601::Errors::StandardError
            DRI::Metadata::Transformations.create_dcmi_period(name) # DCMI Period 'name' is the md value
          end
        end

        return date_range_display
      end

      # Return all date ranges formatted in the right format for indexing and single dates
      # Format: start_date/end_date (ISO8601)
      # @return Hash with all the dates present in the metadata to be indexed as date ranges
      def date_ranges_for_index()
        dates_hash = Hash.new

        creation_date_array = creation_date_start.collect!.with_index do |name, idx|
          name = (idx <= (creation_date_end.length - 1)) ? ("#{name}/#{creation_date_end[idx]}") : name
        end
        captured_date_array = captured_date_start.collect!.with_index do |name, idx|
          name = (idx <= (captured_date_end.length - 1)) ? ("#{name}/#{captured_date_end[idx]}") : name
        end
        issued_date_array = issued_date_start.collect!.with_index do |name, idx|
          name = (idx <= (issued_date_end.length - 1)) ? ("#{name}/#{issued_date_end[idx]}") : name
        end
        subject_date_array = subject_date_start.collect!.with_index do |name, idx|
          name = (idx <= (subject_date_end.length - 1)) ? ("#{name}/#{subject_date_end[idx]}") : name
        end
        date_other_array = date_other_start.collect!.with_index do |name, idx|
          name = (idx <= (date_other_end.length - 1)) ? ("#{name}/#{date_other_end[idx]}") : name
        end
        part_date_array = part_date_start.collect!.with_index do |name, idx|
          name = (idx <= (part_date_end.length - 1)) ? ("#{name}/#{part_date_end[idx]}") : name
        end

        dates_hash["creation_date"] = creation_date_array | creation_date
        dates_hash["captured_date"] = captured_date_array | captured_date
        dates_hash["issued_date"] = issued_date_array | published_date
        dates_hash["subject_date"] = subject_date_array | temporal_coverage
        # dates_hash["date"] = date # Date as namePart[@type='date'] not being indexed as it is not a subject date
        dates_hash["date_other"] = date_other_array | date_other
        dates_hash["part_date"] = part_date_array | part_date

        return dates_hash
      end



      # --------------------------------------------------------------------------------------------------------------

      def custom_validations
        errors = Hash.new
        identifier_result = false
        uri_result = true
        ext_uri_result = true
        title_result = false
        description_result = false
        rights_result = false
        type_result = false
        date_result = false

        # This is the mods identifier used internally in DRI: uniquely identify a record/relationships management
        mods_id_local.each do |curr_local_id|
          identifier_result = true unless curr_local_id.blank?
        end

        id_uri.each do |uri_r|
          uri_result = false unless (!uri_r.blank? && Utils.valid_uri?(uri_r))
        end

        # Check that for external relationships terms, the specified URIs are valid
        related_items_digital.each do |uri_r|
          ext_uri_result = false unless (!uri_r.blank? && Utils.valid_uri?(uri_r))
        end

        title.each do |curr_title|
          title_result = true unless curr_title.blank?
        end

        description.each do |curr_description|
          description_result = true unless curr_description.blank?
        end

        rights.each do |curr_right|
          rights_result = true unless curr_right.blank?
        end

        type.each do |curr_type|
          type_result = true unless curr_type.blank?
        end

        # Creation date can either be: dateCreated, dateIssued, dateCaptured (in this priority order)
        creation_date.each do |curr_date|
          date_result = true unless curr_date.blank?
        end

        # If no single creation date check whether there is a range for dateCreated
        if (!date_result)
          creation_date_start.each do |curr_date|
            date_result = true unless curr_date.blank?
          end
        end
        # If no single creation date check whether there is a range for dateIssued
        if (!date_result)
          issued_date_start.each do |curr_date|
            date_result = true unless curr_date.blank?
          end
        end
        # If no single creation date check whether there is a range for dateCaptured
        if (!date_result)
          captured_date_start.each do |curr_date|
            date_result = true unless curr_date.blank?
          end
        end

        errors[:mods_id_local] = "not present." unless identifier_result == true
        errors[:id_uri] = "Invalid URI present" unless uri_result == true
        errors[:related_items_digital] = "Invalid URI present" unless ext_uri_result == true
        errors[:title] = "can't be blank" if title_result == false
        errors[:type] = "can't be blank" if type_result == false

        # If this is a collection then validate:
        if (!mods_type_collection.nil?)
          errors[:description] = "can't be blank" if description_result == false
          errors[:rights] = "can't be blank" if rights_result == false
          errors[:creation_date] = "can't be blank" if date_result == false
        end

        return errors
      end # custom_validations

      # Load terminology
      load_inherited_terminology      
    end # class
    
  end # module

end # module
