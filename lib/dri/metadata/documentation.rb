module DRI
  module Metadata
    class Documentation < ActiveFedora::RdfxmlRDFDatastream

      # It supports all the DRI Compulsory elements
      property :title, predicate: RDF::DC.title do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :identifier, predicate: RDF::DC.identifier do |index|
        index.as :stored_searchable
      end

      property :creator, predicate: RDF::DC.creator do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_displayable,
                 :sortable
      end

      property :contributor, predicate: RDF::DC.contributor do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_facetable
      end

      property :publisher, predicate: RDF::DC.publisher do |index|
        index.as DRI::Metadata::Descriptors.cleaned_facetable,
                 DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :description, predicate: RDF::DC.description do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :rights, predicate: RDF::DC.rights do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :language, predicate: RDF::DC.language do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata:: Descriptors.language_facetable
      end

      property :date, predicate: RDF::DC.date do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :creation_date, predicate: RDF::DC.created do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :published_date, predicate: RDF::DC.issued do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :subject, predicate: RDF::DC.subject do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_facetable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :resource_type, predicate: RDF::DC.type do |index|
        index.as DRI::Metadata::Descriptors.cleaned_facetable,
                 DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :format, predicate: RDF::DC.format do |index|
        index.as DRI::Metadata::Descriptors.cleaned_facetable,
                 DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :source, predicate: RDF::DC.source do |index|
        index.as DRI::Metadata::Descriptors.cleaned_displayable,
                 DRI::Metadata::Descriptors.cleaned_facetable
      end

      property :coverage, predicate: RDF::DC.coverage do |index|
        index.as DRI::Metadata::Descriptors.cleaned_displayable,
                 DRI::Metadata::Descriptors.cleaned_searchable
      end

      property :geographical_coverage, predicate: RDF::DC.spatial do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_facetable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :temporal_coverage, predicate: RDF::DC.temporal do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :geocode_point, predicate: RDF::DC.Point do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :geocode_box, predicate: RDF::DC.Box do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :temporal_coverage_period, predicate: RDF::DC.Period do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :relation, predicate: RDF::DC.relation do |index|
        index.as :stored_searchable, :facetable
      end

      # Generate MARC Relators fields from the MARC Relators vocabulary
      DRI::Vocabulary::marcRelators.each do |role|
        property role.prepend("role_").to_sym, predicate: DRI::RDFVocabularies::MarcRelatorsVocabulary.send("#{role}") do |index|
          index.as Descriptors.cleaned_facetable,
                   Descriptors.cleaned_searchable,
                   Descriptors.cleaned_displayable
        end
      end

      def collection?
        false
      end

      # Implement this method as implemented also in DRI::Metadata::Base
      def to_xml
        serialize
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

      def to_solr(solr_doc=Hash.new, opts = {})
        solr_doc = super(solr_doc)

        # Index dates here, for display
        solr_doc.merge!(Solrizer.solr_name('creation_date', :stored_searchable) => display_date_for_index(creation_date))
        solr_doc.merge!(Solrizer.solr_name('published_date', :stored_searchable) => display_date_for_index(published_date))
        solr_doc.merge!(Solrizer.solr_name('temporal_coverage', :stored_searchable) => display_date_for_index(temporal_coverage_period) | display_date_for_index(date))
        solr_doc.merge!(Solrizer.solr_name('date', :stored_searchable) => display_date_for_index(date))

        solr_doc = remove_null_values(solr_doc, "creation_date") if solr_doc[Solrizer.solr_name("creation_date", :stored_searchable)].present?
        solr_doc = remove_null_values(solr_doc, "published_date") if solr_doc[Solrizer.solr_name("published_date", :stored_searchable)].present?
        solr_doc = remove_null_values(solr_doc, "date") if solr_doc[Solrizer.solr_name("date", :stored_searchable)].present?
        solr_doc = remove_null_values(solr_doc, "temporal_coverage") if solr_doc[Solrizer.solr_name("temporal_coverage", :stored_searchable)].present?
        solr_doc = remove_null_values(solr_doc, "creator") if solr_doc[Solrizer.solr_name("creator", :stored_searchable)].present?

        # Retrieve list of all people and add them to facet and search indexes in solr document
        person_array = get_person_array()

        solr_doc.merge!(Solrizer.solr_name('person', :facetable) => person_array)
        solr_doc.merge!(Solrizer.solr_name('person', :stored_searchable, type: :text) => person_array | DRI::Metadata::Transformations.transform_name(person_array))

        # title_sorted - A SOLR index for sorting titles
        if (title.length > 0)
          sorted_title = DRI::Metadata::Transformations.transform_title_for_sort(title[0])
          if (sorted_title != "")
            solr_doc.merge!(Solrizer.solr_name('title_sorted', :stored_sortable, type: :string) => [sorted_title])
          end
        end

        # all_metadata - A SOLR index of all the text contained in the XML document
        all_metadata = ""
        get_documentation_properties().each do |property|
          all_metadata += get_values(property).join(" ")
          all_metadata += " "
        end
        solr_doc.merge!(Solrizer.solr_name("all_metadata", :stored_searchable, type: :text) => [all_metadata])

        # Split facets into different languages based on xml:lang
        #faceted_language_indexes = Hash.new
        #faceted_language_indexes.merge! split_array_into_languages("title")
        #faceted_language_indexes.merge! split_array_into_languages("rights")
        #faceted_language_indexes.merge! split_array_into_languages("subject")
        #faceted_language_indexes.merge! split_array_into_languages("coverage")
        #faceted_language_indexes.merge! split_array_into_languages("temporal_coverage")
        #faceted_language_indexes.merge! split_array_into_languages("geographical_coverage")
        #faceted_language_indexes.merge! split_array_into_languages("description")
        #faceted_language_indexes.merge! split_array_into_languages("source")
        #faceted_language_indexes.merge! split_array_into_languages("name_coverage")

        #faceted_language_indexes.each do | key, value |
        #  solr_doc.merge!(Solrizer.solr_name(key, :stored_searchable, type: :text) => value)
        #  solr_doc.merge!(Solrizer.solr_name(key, :facetable, type: :text) => value)
        #end

        # dateRangeField is defined in Solr's schema.xml as a field of type date_range (solr.SpatialRecursivePrefixTreeFieldType)
        cdate_ranges = DRI::Metadata::Transformations.transform_date_ranges({ "creation_date" => creation_date})
        pdate_ranges = DRI::Metadata::Transformations.transform_date_ranges({ "published_date" => published_date})
        sdate_ranges = DRI::Metadata::Transformations.transform_date_ranges({ "date" => date, "temporal_coverage" => temporal_coverage | temporal_coverage_period})

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
        solr_doc.merge!(Solrizer.solr_name(DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD, :stored_searchable) => geospatial_hash[:name]) unless geospatial_hash[:name].empty?
        solr_doc.merge!(Solrizer.solr_name(DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD, :facetable, type: :text) => geospatial_hash[:name]) unless geospatial_hash[:name].empty?
        solr_doc.merge!(Solrizer.solr_name('geojson', :stored_searchable, type: :symbol) => geospatial_hash[:json]) unless geospatial_hash[:json].empty?


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

      def get_documentation_properties
        [:creator, :title, :subject, :description, :contributor, :publisher, :language,
            :date, :source, :geographical_coverage, :temporal_coverage, :temporal_coverage_period, :creation_date, :published_date,
            :resource_type, :format, :coverage, :rights, :identifier,
            :geocode_point, :geocode_box, :relation]
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

      def type
        resource_type
      end

      def remove_null_values solr_doc, field
        [:stored_searchable, :facetable].each do |index_type|
          if solr_doc[Solrizer.solr_name(field, index_type)].present?
            solr_doc[Solrizer.solr_name(field, index_type)].delete_if{|v| /^null$/i.match(v) || (!v.nil? && v.empty?)}
          end
        end

        solr_doc
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

        resource_type.each do |curr_type|
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

        errors[:title] = "can't be blank" if title_result == false
        errors[:description] = "can't be blank" if description_result == false
        errors[:rights] = "can't be blank" if rights_result == false
        errors[:resource_type] = "can't be blank" if type_result == false
        errors[:date] = "can't be blank" if date_result == false

        return errors
      end # custom_validations

      def apply_prefix(name)
        "#{name}"
      end
    end
  end
end