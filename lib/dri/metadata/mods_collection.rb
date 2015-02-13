module DRI

  module Metadata

    # An ActiveFedora datastream that interacts with a collection of MODS records.
    # MODS Schema version changed to 3.5 (July 8, 2013) based on DRI MODS guidelines.
    class ModsCollection < DRI::Metadata::Base

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
          # Map to the mods record identifier (absolute xpath here)
          t.identifier(:path => "mods/mods:identifier", :namespace_prefix => MODS_NS_PREFIX)
          t.doi(:ref => :identifier, :attributes => {:type=>"doi"}, :namespace_prefix => MODS_NS_PREFIX)
          t.uri(:ref => :identifier, :attributes => {:type=>"uri"}, :namespace_prefix => MODS_NS_PREFIX)

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
          t.language(:path => "language", :namespace_prefix => MODS_NS_PREFIX) {
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

          t.type_resource(:path => "typeOfResource", :attributes => {"collection" => "yes"}, :namespace_prefix => MODS_NS_PREFIX)

          t.genre(:path => "genre", :namespace_prefix => MODS_NS_PREFIX) {
            t.type(:path => {:attribute => "type"})
          }

          t.physical_description(:path => "physicalDescription", :namespace_prefix => MODS_NS_PREFIX) {
            # The size of the collection
            t.extent(:namespace_prefix => MODS_NS_PREFIX)
            t.note(:ref=>[:note])
          }
          # Related Item
          t.related_item(:path => "relatedItem", :namespace_prefix => MODS_NS_PREFIX) {
            t.identifier_(:ref => [:identifier], :namespace_prefix => MODS_NS_PREFIX)
            t.title_info(:ref => [:title_info])
            t.type_related_item(:ref => [:type_resource], :namespace_prefix => MODS_NS_PREFIX)
            t.genre_(:ref=> [:genre])
          }

          # tableOfContents
          t.table_contents(:path => "tableOfContents", :namespace_prefix => MODS_NS_PREFIX) {
            t.format_at(:path => {:attribute => "altFormat"})
            t.content_at(:path => {:attribute => "altContent"})
          }

          # Note
          t.note(:path=>"note", :namespace_prefix => MODS_NS_PREFIX) {
            t.label_at(:path => {:attribute=> "displayLabel"})
            t.type_at(:path => {:attribute=> "type"})
          }

          t.related_items_ids(:path => "relatedItem/mods:identifier", :namespace_prefix => MODS_NS_PREFIX)

          # ----------------------------------------------------------------------------------------------------------
          # Term proxies definition

          # Title
          t.title(:proxy => [:title_info, :main_title], :index_as => [Descriptors.cleaned_searchable,
                                                                      Descriptors.cleaned_displayable])
          # Creator
          t.creator(:path => "name[mods:role/mods:roleTerm/@authority='marcrelator' and mods:role/mods:roleTerm/@type='code' and mods:role/mods:roleTerm = ('cre' or 'aut')]/mods:namePart",
                    :index_as=>[Descriptors.cleaned_facetable, Descriptors.cleaned_searchable,
                                Descriptors.cleaned_displayable,  :sortable],
                    :namespace_prefix => MODS_NS_PREFIX)
          # Contributor
          t.contributor(:path => "name[mods:role/mods:roleTerm/@authority='marcrelator' and mods:role/mods:roleTerm/@type='code' and mods:role/mods:roleTerm = 'ctb']/mods:namePart",
                        :index_as=>[Descriptors.cleaned_facetable, Descriptors.cleaned_searchable,
                                    Descriptors.cleaned_displayable,  :sortable],
                        :namespace_prefix => MODS_NS_PREFIX)
          # Description: abstract, tableOfContents, or note
          t.description(:path => "abstract", :index_as => [Descriptors.cleaned_searchable,
                                                           Descriptors.cleaned_displayable],
                        :namespace_prefix => MODS_NS_PREFIX)
          # Subject: defaults to subject/topic
          t.subject_(:path => "subject/mods:topic", :index_as=>[Descriptors.cleaned_searchable,
                                                           Descriptors.cleaned_facetable,
                                                           Descriptors.cleaned_displayable],
                     :namespace_prefix => MODS_NS_PREFIX)

          # Source
          # TODO - decide the preference: place for location, dates for temporal
          t.source(:path => "originInfo/mods:place/mods:placeTerm", :index_as=>[Descriptors.cleaned_displayable,
                                                                      Descriptors.cleaned_facetable],
                   :namespace_prefix => MODS_NS_PREFIX)
          # Type
          t.type(:proxy => [:type_resource], :index_as=>[Descriptors.cleaned_facetable,
                                                         Descriptors.cleaned_searchable,
                                                         Descriptors.cleaned_displayable],
                 :namespace_prefix => MODS_NS_PREFIX)

          # Rights - needs special indexing
          t.rights(:path => "accessCondition", :index_as=>[Descriptors.cleaned_searchable,
                                                           Descriptors.cleaned_displayable],
                   :namespace_prefix => MODS_NS_PREFIX)
          # Publisher
          t.publisher(:path => "originInfo/mods:publisher", :index_as => [Descriptors.cleaned_facetable,
                                                                     Descriptors.cleaned_searchable,
                                                                     Descriptors.cleaned_displayable],
                      :namespace_prefix => MODS_NS_PREFIX)
          # Published_date
          t.published_date(:path => "originInfo/mods:dateIssued", :index_as=>[Descriptors.cleaned_searchable,
                                                                         Descriptors.cleaned_displayable],
                           :namespace_prefix => MODS_NS_PREFIX)
          # Creation_date
          t.creation_date(:path => "originInfo/mods:dateCreated", :index_as=>[Descriptors.cleaned_searchable,
                                                                         Descriptors.cleaned_displayable],
                          :namespace_prefix => MODS_NS_PREFIX)

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

          # MODS Terms
          t.subtitle(:proxy => [:title_info, :subtitle], :index_as => [Descriptors.cleaned_searchable,
                                                                       Descriptors.cleaned_displayable])
          t.abstract(:path => "abstract", :index_as => [Descriptors.cleaned_searchable,
                                                        Descriptors.cleaned_displayable],
                     :namespace_prefix => MODS_NS_PREFIX)
          t.toc_(:ref => :table_contents, :index_as => [Descriptors.cleaned_searchable,
                                                       Descriptors.cleaned_displayable])

          # TODO - Check about @type for note - http://www.loc.gov/standards/mods/mods-notes.html
          t.note(:path => "note", :index_as => [Descriptors.cleaned_searchable,
                                                Descriptors.cleaned_displayable], :namespace_prefix => MODS_NS_PREFIX)

          # Subject name
          t.subject_name(:proxy => [:main_subject, :name_topic])

          # Subject: temporal, date
          t.subject_temporal(:path => "subject/mods:temporal", :namespace_prefix => MODS_NS_PREFIX)
          t.subject_date_start(:path => "subject/mods:temporal", :attributes=>{:encoding=>"w3cdtf", :point=>"start"},
                               :namespace_prefix => MODS_NS_PREFIX)
          t.subject_date_end(:path => "subject/mods:temporal", :attributes=>{:encoding=>"w3cdtf", :point=>"end"},
                             :namespace_prefix => MODS_NS_PREFIX)
          t.date(:proxy => [:name, :date])
          t.date_captured(:proxy => [:origin_info, :date_captured])
          t.date_other(:proxy => [:origin_info, :date_other])

          # Other mappings to geographical/temporal
          t.hierarchical_geographic(:path => "subject/mods:hierarchicalGeographic", :namespace_prefix => MODS_NS_PREFIX)
          t.hierarchical_geographic_lang(:path => "subject/mods:hierarchicalGeographic/@lang")
          t.cartographics_scale(:path => "subject/mods:cartographics/mods:scale", :namespace_prefix => MODS_NS_PREFIX)
          t.cartographics_coordinates(:path => "subject/mods:cartographics/mods:coordinates", :namespace_prefix => MODS_NS_PREFIX)
          t.cartographics_projection(:path => "subject/mods:cartographics/mods:projection", :namespace_prefix => MODS_NS_PREFIX)

        end # End set terminology
      end

      # TODO - Override OM method
      def to_solr(solr_doc=Hash.new)
        super(solr_doc)

        solr_doc
      end

      def metadata_path field
        recognised_attributes = [ :title, :rights, :description, :language, :subject, :contributor,
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
          xml.mods(:version => "3.5", "xmlns:xlink" => "http://www.w3.org/1999/xlink",
                   "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
                   "xmlns:mods" => MODS_NS,
                   "xmlns:marcrel" => "http://www.loc.gov/marc.relators/",
                   "xmlns:dcterms" => "http://purl.org/dc/terms/",
                   "xmlns:#{CR_NS_PREFIX}" => CR_NS,
                   "xsi:schemaLocation" => MODS_SCHEMA) {
            xml['mods'].titleInfo.title
            xml['mods'].abstract
            xml['mods'].typeOfResource("collection" => "yes", "type" => "dct"){xml.text("Collection")}
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

      def custom_validations
        errors = Hash.new

        title_result = false
        description_result = false
        rights_result = false
        type_result = false
        date_result = false

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

        creation_date.each do |curr_date|
          date_result = true unless curr_date.blank?
        end

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
