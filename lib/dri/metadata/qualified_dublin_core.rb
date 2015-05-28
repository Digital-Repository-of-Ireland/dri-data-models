module DRI

  module Metadata

    # An ActiveFedora datastream that interacts with Qualified DC Metadata.

    class QualifiedDublinCore < DRI::Metadata::Base

      # Set OM (Opinionated Metadata) terminology
      def self.load_inherited_terminology
        set_terminology do |t|
          t.root(:path=>"*") # Selects the root node of the XML document

          # Simple Dublin Core Fields
          t.title(:namespace_prefix=>"dc", :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable]){
            t.title_lang(:path=>{:attribute=> "xml:lang"})
          }
          t.rights(:namespace_prefix=>"dc", :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable]){
            t.rights_lang(:path=>{:attribute=> "xml:lang"})
          }
          t.description(:namespace_prefix=>"dc", :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable]) {
            t.description_lang(:path=>{:attribute=> "xml:lang"})
          }
          t.language(:namespace_prefix=>"dc", :index_as=>[Descriptors.cleaned_searchable, Descriptors.language_facetable])
          t.subject(:namespace_prefix=>"dc", :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable]) {
            t.subject_lang(:path=>{:attribute=> "xml:lang"})
          }
          t.subject_lang(:proxy=>[:subject, :subject_lang])
          t.date(:namespace_prefix=>"dc")
          t.contributor(:path=>"contributor", :namespace_prefix=>"dc", :index_as=>[Descriptors.cleaned_facetable, Descriptors.cleaned_searchable])
          t.source(:path=>"source", :namespace_prefix=>"dc", :index_as=>[Descriptors.cleaned_displayable, Descriptors.cleaned_facetable]) {
            t.source_lang(:path=>{:attribute=> "xml:lang"})
          }
          t.publisher(:path=>"publisher", :namespace_prefix=>"dc", :index_as=>[Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
          t.coverage(:namespace_prefix=>"dc", :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_displayable]) {
            t.coverage_lang(:path=>{:attribute=> "xml:lang"})
          }
          t.relation(:namespace_prefix=>"dc", :index_as=>[Descriptors.cleaned_displayable, Descriptors.cleaned_facetable])
          t.external_relation(:path=>"relation", :namespace_prefix=>"dc", :attributes => {"xsi:type"=>"dcterms:URI"}, :index_as=>[Descriptors.cleaned_displayable, Descriptors.cleaned_facetable])
          t.creator(:namespace_prefix=>"dc", :index_as=>[Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable,  :sortable])
          t.format(:namespace_prefix=>"dc", :index_as=>[Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
          t.type(:namespace_prefix=>"dc", :index_as=>[Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])

          t.identifier(:namespace_prefix=>"dc")
          # For sorting in the UI, same as MODS and MARC
          t.id_asset(:path => "identifier[1]", :namespace_prefix=>"dc", :index_as => [:stored_sortable])
          t.qdc_id(:ref => :identifier, :index_as => [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])

          # Qualified Dublin Core fields
          t.published_date(:path=>"issued", :namespace_prefix=>"dcterms")
          t.creation_date(:path=>"created", :namespace_prefix=>"dcterms")
          t.geographical_coverage(:path=>"spatial", :namespace_prefix=>"dcterms", :index_as=>[Descriptors.cleaned_searchable, Descriptors.cleaned_facetable, Descriptors.cleaned_displayable])  {
            t.geographical_coverage_lang(:path=>{:attribute=> "xml:lang"})
          }
          t.temporal_coverage(:path=>"temporal", :namespace_prefix=>"dcterms") {
            t.temporal_coverage_lang(:path=>{:attribute=> "xml:lang"})
          }
          t.geocode_point(:ref=>:geographical_coverage, :attributes=> {"xsi:type"=>"dcterms:Point"}, :index_as=> [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
          t.geocode_box(:ref=>:geographical_coverage, :attributes=> {"xsi:type"=>"dcterms:Box"}, :index_as=> [Descriptors.cleaned_searchable, Descriptors.cleaned_displayable])
          t.name_coverage(:path => "dpc", :namespace_prefix=>"marcrel", :index_as=>[Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable]) {
           t.name_coverage_lang(:path=>{:attribute=> "xml:lang"})
          }

          # Generate MARC Relators fields from the MARC Relators vocabulary
          DRI::Vocabulary::marcRelators.each do |role|
            t.send "role_"+role, :path=>role, :namespace_prefix=>"marcrel", :index_as=>[Descriptors.cleaned_facetable, Descriptors.cleaned_searchable, Descriptors.cleaned_displayable]
          end

          # Relationships for QDC
          DRI::Vocabulary::qdcRelationshipTypes.each do |rel|
            t.send "relation_ids_" + rel,
                   :path=>"#{rel}[not(@xsi:type='dcterms:URI')]",
                   :namespace_prefix => "dcterms"
          end

          # External relationships (contain uri to a resource external to DRI)
          DRI::Vocabulary::qdcRelationshipTypes.each do |rel|
            t.send "ext_related_items_ids_" + rel,
                   :path=>rel,
                   :attributes=>{"xsi:type" => "dcterms:URI"},
                   :namespace_prefix => "dcterms"
          end
        end

      end
      
      def synchronize_metadata_on_save
        false
      end

      def metadata_path field
          recognised_attributes = [:title, :rights, :description, :language, :subject, :subject_lang, :date, :contributor,
                                    :source, :publisher, :coverage, :coverage_lang, :relation, :creator, :format, :type,
                                    :identifier, :published_date, :creation_date, :geographical_coverage, :geographical_coverage_lang,
                                    :temporal_coverage, :temporal_coverage_lang, :geocode_point, :geocode_box]
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
            xml.qualifieddc(
               "xmlns:dc" => "http://purl.org/dc/elements/1.1/",
               "xmlns:dcterms" => "http://purl.org/dc/terms/",
               "xmlns:marcrel" => "http://www.loc.gov/marc.relators/",
               "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
               "xsi:schemaLocation" => "http://www.loc.gov/marc.relators/ http://imlsdcc2.grainger.illinois.edu/registry/marcrel.xsd",
               "xsi:noNamespaceSchemaLocation"=>"http://dublincore.org/schemas/xmls/qdc/2008/02/11/qualifieddc.xsd") {
                 xml['dc'].title 
                 xml['dc'].description
            }
          end
          return builder.doc
      end

      # merge in special facets (e.g. person) into solr document
      def to_solr(solr_doc=Hash.new, opts = {})
        solr_doc = super(solr_doc)

        # Index dates here, for display
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('creation_date', :stored_searchable) => display_date_for_index(creation_date))
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('published_date', :stored_searchable) => display_date_for_index(published_date))
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('temporal_coverage', :stored_searchable) => display_date_for_index(temporal_coverage) | display_date_for_index(date))
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('date', :stored_searchable) => display_date_for_index(date))

        solr_doc = remove_null_values(solr_doc, "creation_date") if solr_doc[ActiveFedora::SolrQueryBuilder.solr_name("creation_date", :stored_searchable)].present?
        solr_doc = remove_null_values(solr_doc, "published_date") if solr_doc[ActiveFedora::SolrQueryBuilder.solr_name("published_date", :stored_searchable)].present?
        solr_doc = remove_null_values(solr_doc, "date") if solr_doc[ActiveFedora::SolrQueryBuilder.solr_name("date", :stored_searchable)].present?
        solr_doc = remove_null_values(solr_doc, "temporal_coverage") if solr_doc[ActiveFedora::SolrQueryBuilder.solr_name("temporal_coverage", :stored_searchable)].present?
        solr_doc = remove_null_values(solr_doc, "creator") if solr_doc[ActiveFedora::SolrQueryBuilder.solr_name("creator", :stored_searchable)].present?

        # Retrieve list of all people and add them to facet and search indexes in solr document
        person_array = get_person_array()

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('person', :facetable) => person_array)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('person', :stored_searchable, type: :text) => person_array | DRI::Metadata::Transformations.transform_name(person_array))
        
        # title_sorted - A SOLR index for sorting titles
        if (title.length > 0)
          sorted_title = DRI::Metadata::Transformations.transform_title_for_sort(title[0])
          if (sorted_title != "")
            solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('title_sorted', :stored_sortable, type: :string) => [sorted_title])
          end
        end

       # all_metadata - A SOLR index of all the text contained in the XML document
        all_metadata = ""
        ng_xml.xpath("//text()").each do |text_node|
          all_metadata += text_node.text
          all_metadata += " "
        end
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name("all_metadata", :stored_searchable, type: :text) => [all_metadata])

        # Split facets into different languages based on xml:lang
        faceted_language_indexes = Hash.new
        faceted_language_indexes.merge! split_array_into_languages("title")
        faceted_language_indexes.merge! split_array_into_languages("rights")
        faceted_language_indexes.merge! split_array_into_languages("subject")
        faceted_language_indexes.merge! split_array_into_languages("coverage")
        faceted_language_indexes.merge! split_array_into_languages("temporal_coverage")
        faceted_language_indexes.merge! split_array_into_languages("geographical_coverage")
        faceted_language_indexes.merge! split_array_into_languages("description")
        faceted_language_indexes.merge! split_array_into_languages("source")
        faceted_language_indexes.merge! split_array_into_languages("name_coverage")

        faceted_language_indexes.each do | key, value |
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name(key, :stored_searchable, type: :text) => value)
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name(key, :facetable, type: :text) => value)
        end

        # Indices for external relationships (to be displayed as URL)
        external_rels = *(DRI::Vocabulary::qdcRelationshipTypes.map { |s| s.prepend("ext_related_items_ids_").to_sym})

        external_rels.each do |elem|
          solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name(elem, :stored_searchable) => self.send(elem)) unless self.send(elem) == []
        end


        # dateRangeField is defined in Solr's schema.xml as a field of type date_range (solr.SpatialRecursivePrefixTreeFieldType)
        cdate_ranges = DRI::Metadata::Transformations.transform_date_ranges({ "creation_date" => creation_date})
        pdate_ranges = DRI::Metadata::Transformations.transform_date_ranges({ "published_date" => published_date})
        sdate_ranges = DRI::Metadata::Transformations.transform_date_ranges({ "date" => date, "temporal_coverage" => temporal_coverage})

        solr_doc.merge!(DRI::Metadata::Transformations::CREATION_DATE_RANGE_SOLR_FIELD => cdate_ranges) unless cdate_ranges == []
        solr_doc.merge!(DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_SOLR_FIELD => pdate_ranges) unless pdate_ranges == []
        solr_doc.merge!(DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_SOLR_FIELD => sdate_ranges) unless sdate_ranges == []

        # Index dcterms Point and Box data into geospatial Solr field (location_rpt)
        geospatial_hash = DRI::Metadata::Transformations.transform_geospatial({"geographical_coverage" => geocode_point | geocode_box})

        uris = geographical_coverage.select{ |i| i[/\A#{URI::regexp(['http', 'https'])}\z/] }
        if uris.present?
          linked_data = DRI::Metadata::Transformations.transform_geospatial({"geographical_coverage" => uris})
  
          geospatial_hash[:coords].concat(linked_data[:coords])
          geospatial_hash[:name].concat(linked_data[:name])
          geospatial_hash[:json].concat(linked_data[:json])
        end

        solr_doc.merge!(DRI::Metadata::Transformations::GEOSPATIAL_SOLR_FIELD => geospatial_hash[:coords]) unless geospatial_hash[:coords].empty?
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name(DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD, :stored_searchable) => geospatial_hash[:name]) unless geospatial_hash[:name].empty?
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name(DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD, :facetable, type: :text) => geospatial_hash[:name]) unless geospatial_hash[:name].empty?
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('geojson', :stored_searchable, type: :symbol) => geospatial_hash[:json]) unless geospatial_hash[:json].empty?
        # Split date ranges into separate indexes
        #date_ranges = Transformations.transform_date_ranges({ "date" => date, "published_date" => published_date, "creation_date" => creation_date})
        #solr_doc.merge!(date_ranges)

        solr_doc
      end

      def display_date_for_index(date_field=[])
        date_field = date_field.delete_if{|v| /^null$/i.match(v)}
        date_field.collect! do |value|
          begin
            if value.empty? || DRI::Metadata::Transformations.dcmi_period?(value) # return value for display as it is
              # If value.empty? is cleaned afterwards
              value
            else
              # Date range in ISO8601 format?
              sdate = ISO8601::DateTime.new(value).strftime("%Y-%m-%d")
              DRI::Metadata::Transformations.create_dcmi_period(value, sdate)
            end
          rescue ISO8601::Errors::StandardError
            DRI::Metadata::Transformations.create_dcmi_period(value) # DCMI Period 'name' is the md value
          end
        end
      end

      # Some indexes may need to be split up into different languages
      def split_array_into_languages(index_name="")
        results = Hash.new

        if index_name == ""
          return results
        end
        
        array_values = send index_name
        # Remove empty values from the source metadata: e.g. remove <dc:subject/>
        array_values = array_values.reject(&:empty?)

        array_values.each_with_index do |value, i|
          value_lang = send(index_name, i).send(index_name+"_lang")

            foo = "eng"

            if (value_lang.length > 0) 
              foo = value_lang[0].strip
            end

            foo = DRI::Metadata::Descriptors.standardise_language_code foo

            if foo == nil
              foo = "eng"
            end

            if !results.has_key? index_name+"_"+foo
              results[index_name+"_"+foo] = [value]
            else
              results[index_name+"_"+foo] |= [value]
            end
        end

        return results
      end

      # Creates an array of all names stored in the metadata
      def get_person_array()
        people = contributor | publisher
        people |= creator.reject{|c| /^null$/i.match(c)}  

        DRI::Vocabulary::marcRelators.each do |role|
          people |= send("role_"+role)
        end

        people
      end

      def collection?
        type.include? "Collection"
      end

      def custom_validations
        errors = Hash.new

        uri_result = true
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

        date.each do |curr_date|
          date_result = true unless curr_date.blank?
        end

        if !date_result
          creation_date.each do |curr_date|
            date_result = true unless curr_date.blank?
          end
        end

        if !date_result
          published_date.each do |curr_date|
            date_result = true unless curr_date.blank?
          end
        end

        # Check that for external relationships terms, the specified URIs are valid
        external_relation.each do |uri_r|
          uri_result = false unless (!uri_r.blank? && Utils.valid_uri?(uri_r))
        end

        errors[:title] = "can't be blank" if title_result == false
        errors[:description] = "can't be blank" if description_result == false
        errors[:external_relation] = "Includes invalid URI" if uri_result == false
        errors[:rights] = "can't be blank" if rights_result == false
        errors[:type] = "can't be blank" if type_result == false
        errors[:date] = "can't be blank" if date_result == false

        return errors
      end

      # Load Dublin Core terminology
      load_inherited_terminology      
    end # class
    
  end # module

end # module
