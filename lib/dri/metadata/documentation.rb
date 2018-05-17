# DRI namespace
module DRI
  # Metadata namespace
  module Metadata
    # Implements the descMetadata datastream for DRI::Documentation digital objects as an AF
    # RDFXMLDatastream
    class Documentation < ActiveFedora::RDFXMLDatastream
      # It supports all the DRI Compulsory elements
      property :title, predicate: RDF::Vocab::DC.title do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :identifier, predicate: RDF::Vocab::DC.identifier do |index|
        index.as :stored_searchable
      end

      property :creator, predicate: RDF::Vocab::DC.creator do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_displayable,
                 :sortable
      end

      property :contributor, predicate: RDF::Vocab::DC.contributor do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_facetable
      end

      property :publisher, predicate: RDF::Vocab::DC.publisher do |index|
        index.as DRI::Metadata::Descriptors.cleaned_facetable,
                 DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :description, predicate: RDF::Vocab::DC.description do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :rights, predicate: RDF::Vocab::DC.rights do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :language, predicate: RDF::Vocab::DC.language do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata:: Descriptors.language_facetable
      end

      property :date, predicate: RDF::Vocab::DC.date do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :creation_date, predicate: RDF::Vocab::DC.created do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :published_date, predicate: RDF::Vocab::DC.issued do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :subject, predicate: RDF::Vocab::DC.subject do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_facetable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :resource_type, predicate: RDF::Vocab::DC.type do |index|
        index.as DRI::Metadata::Descriptors.cleaned_facetable,
                 DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :format, predicate: RDF::Vocab::DC.format do |index|
        index.as DRI::Metadata::Descriptors.cleaned_facetable,
                 DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :source, predicate: RDF::Vocab::DC.source do |index|
        index.as DRI::Metadata::Descriptors.cleaned_displayable,
                 DRI::Metadata::Descriptors.cleaned_facetable
      end

      property :coverage, predicate: RDF::Vocab::DC.coverage do |index|
        index.as DRI::Metadata::Descriptors.cleaned_displayable,
                 DRI::Metadata::Descriptors.cleaned_searchable
      end

      property :geographical_coverage, predicate: RDF::Vocab::DC.spatial do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_facetable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :temporal_coverage, predicate: RDF::Vocab::DC.temporal do |index|
        index.as DRI::Metadata::Descriptors.cleaned_searchable,
                 DRI::Metadata::Descriptors.cleaned_facetable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :geocode_point, predicate: RDF::Vocab::DC.Point

      property :geocode_box, predicate: RDF::Vocab::DC.Box

      property :temporal_coverage_period, predicate: RDF::Vocab::DC.Period

      property :relation, predicate: RDF::Vocab::DC.relation do |index|
        index.as :stored_searchable, :facetable
      end

      # Generate MARC Relators fields from the MARC Relators vocabulary
      DRI::Vocabulary.marc_relators.each do |role|
        property role.prepend('role_').to_sym, predicate: DRI::RDFVocabularies::MarcRelatorsVocabulary.send("#{role}") do |index|
          index.as Descriptors.cleaned_facetable,
                   Descriptors.cleaned_searchable,
                   Descriptors.cleaned_displayable
        end
      end

      # Determine whether the metadata describes a collection
      def collection?
        # Always false, documentation objects can't be collections
        false
      end

      # Implement this method as implemented also in DRI::Metadata::Base
      # and this class does not inherit from Base
      def to_xml
        serialize
      end

      # Roles attribute setter
      # @example Sample Hash:
      #   { 'name' => ['Test host', 'new producer'],
      #     'type' => ['role_hst', 'role_pro']
      #   }
      # @param [Hash] roles hash with metadata marcrelator values
      # @option roles [Array<String>] :name the metadata values for the marcrelators in :type
      # @option roles [Array<String>] :type the marcrelator codes
      def roles=(roles)
        return unless roles.is_a?(Hash)
        return unless roles.key?('type') && roles.key?('name') && (roles['type'].size == roles['name'].size)

        changed_roles = {}
        roles['type'].uniq.each { |role| changed_roles[role] = [] }

        roles['type'].each_with_index do |role, i|
          unless roles['name'][i].empty?
            changed_roles[role].push(roles['name'][i])
          end
        end

        changed_roles.keys.each { |role| send("#{role}=", changed_roles[role]) }
      end

      # Override from AF Solrizer for datastreams
      # Update solr_doc Hash for index into Solr from the metadata
      # @param [Hash] solr_doc the solr document hash
      # @param [Hash] opts additional custom options
      # @return [Hash] the updated solr_doc hash for Solr index
      def to_solr(solr_doc = {}, opts = {})
        solr_doc = super(solr_doc, opts)

        # Index dates here, for display
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('creation_date', :stored_searchable) => display_date_for_index(creation_date))
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('published_date', :stored_searchable) => display_date_for_index(published_date))
        
        temporal_coverage_dates = display_date_for_index(temporal_coverage_period)
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('temporal_coverage', :stored_searchable) => temporal_coverage_dates)
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('temporal_coverage', :facetable) => temporal_coverage_dates)

        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('date', :stored_searchable) => display_date_for_index(date))

        solr_doc = remove_null_values(solr_doc, 'creation_date') if solr_doc[ActiveFedora.index_field_mapper.solr_name('creation_date', :stored_searchable)].present?
        solr_doc = remove_null_values(solr_doc, 'published_date') if solr_doc[ActiveFedora.index_field_mapper.solr_name('published_date', :stored_searchable)].present?
        solr_doc = remove_null_values(solr_doc, 'date') if solr_doc[ActiveFedora.index_field_mapper.solr_name('date', :stored_searchable)].present?
        solr_doc = remove_null_values(solr_doc, 'temporal_coverage') if solr_doc[ActiveFedora.index_field_mapper.solr_name('temporal_coverage', :stored_searchable)].present?
        solr_doc = remove_null_values(solr_doc, 'creator') if solr_doc[ActiveFedora.index_field_mapper.solr_name('creator', :stored_searchable)].present?

        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('type', :stored_searchable) => resource_type)
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('type', :facetable) => resource_type)

        # Retrieve list of all people and add them to facet and search indexes in solr document
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('person', :facetable) => person_array)
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('person', :stored_searchable, type: :text) => person_array | DRI::Metadata::Transformations.transform_name(person_array))

        # title_sorted - A SOLR index for sorting titles
        unless title.empty?
          sorted_title = DRI::Metadata::Transformations.transform_title_for_sort(title[0])
          unless sorted_title.empty?
            solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('title_sorted', :stored_sortable, type: :string) => [sorted_title])
          end
        end

        # all_metadata
        # SOLR index of all text nodes in the XML document
        all_metadata = ''

        documentation_properties.each do |property|
          all_metadata += get_values(property).join(' ')
          all_metadata += ' '
        end
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('all_metadata', :stored_searchable, type: :text) => [all_metadata])

        cdate_ranges = DRI::Metadata::Transformations.transform_date_ranges({ 'creation_date' => creation_date })
        pdate_ranges = DRI::Metadata::Transformations.transform_date_ranges({ 'published_date' => published_date })
        ddate_ranges = DRI::Metadata::Transformations.transform_date_ranges({ 'date' => date })
        sdate_ranges = DRI::Metadata::Transformations.transform_date_ranges({ 'temporal_coverage' => temporal_coverage | temporal_coverage_period })

        solr_doc.merge!(DRI::Metadata::Transformations::DATE_RANGE_SOLR_FIELD => ddate_ranges) unless ddate_ranges.empty?
        
        if cdate_ranges.present?
          solr_doc.merge!(DRI::Metadata::Transformations::CREATION_DATE_RANGE_SOLR_FIELD => cdate_ranges)
          cdate_years = DRI::Metadata::Transformations.date_range_years(cdate_ranges)
          solr_doc.merge!(DRI::Metadata::Transformations::CREATION_DATE_YEAR_SOLR_FIELD => cdate_years)
          solr_doc.merge!(DRI::Metadata::Transformations::CREATION_DATE_RANGE_START_SOLR_FIELD => cdate_years.min)
          solr_doc.merge!(DRI::Metadata::Transformations::CREATION_DATE_RANGE_END_SOLR_FIELD => cdate_years.max)
        end

        if pdate_ranges.present?
          solr_doc.merge!(DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_SOLR_FIELD => pdate_ranges)
          pdate_years = DRI::Metadata::Transformations.date_range_years(pdate_ranges)
          solr_doc.merge!(DRI::Metadata::Transformations::PUBLISHED_DATE_YEAR_SOLR_FIELD => pdate_years)
          solr_doc.merge!(DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_START_SOLR_FIELD => pdate_years.min)
          solr_doc.merge!(DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_END_SOLR_FIELD => pdate_years.max)
        end
        
        if sdate_ranges.present?
          solr_doc.merge!(DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_SOLR_FIELD => sdate_ranges)
          sdate_years = DRI::Metadata::Transformations.date_range_years(sdate_ranges).minmax
          solr_doc.merge!(DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_START_SOLR_FIELD => sdate_years[0])
          solr_doc.merge!(DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_END_SOLR_FIELD => sdate_years[1])
        end

        # Index dcterms Point and Box data into geospatial Solr field
        geospatial_hash = DRI::Metadata::Transformations.transform_geospatial(
          { 
            'geographical_coverage' => geocode_point | geocode_box | geographical_coverage.reject{ |i| i[/\A#{URI.regexp(['http', 'https'])}\z/] } 
          }
        )

        uris = geographical_coverage.select{ |i| i[/\A#{URI.regexp(['http', 'https'])}\z/] }
        if uris.present?
          linked_data = DRI::Metadata::Transformations.transform_geospatial({ 'geographical_coverage' => uris })

          geospatial_hash[:coords].concat(linked_data[:coords])
          geospatial_hash[:name].concat(linked_data[:name])
          geospatial_hash[:json].concat(linked_data[:json])
        end
        solr_doc.merge!(DRI::Metadata::Transformations::GEOSPATIAL_SOLR_FIELD => geospatial_hash[:coords]) unless geospatial_hash[:coords].empty?
        
        unless geospatial_hash[:name].empty?
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name(DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD, :stored_searchable) => geospatial_hash[:name])
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name(DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD, :facetable, type: :text) => geospatial_hash[:name])
        end

        unless geospatial_hash[:json].empty?
          solr_doc.merge!(DRI::Metadata::Transformations::GEOJSON_SOLR_FIELD => geospatial_hash[:json])
        end

        solr_doc
      end

      # Transforms metadata date strings into DCMI Period encoded strings for displayable indices
      # @param [String] date_field the date string
      # @return [String] the DCMI Period encoded date string for display
      def display_date_for_index(date_field)
        date_field = date_field.delete_if { |v| /^null$/i.match(v) }

        date_field.collect! do |value|
          begin
            # return value for display as it is
            if value.empty? || DRI::Metadata::Transformations.dcmi_period?(value)
              # If value.empty? is cleaned afterwards
              value
            else
              # Date range in ISO8601 format?
              formatted_date = ISO8601::DateTime.new(value).strftime('%Y-%m-%d')
              DRI::Metadata::Transformations.create_dcmi_period(value, formatted_date)
            end
          rescue ISO8601::Errors::StandardError
            # DCMI Period 'name' is the md value
            DRI::Metadata::Transformations.create_dcmi_period(value)
          end
        end
      end

      # Returns an array of symbols for all the DRI::Documentation metadata supported properties
      # @return [Array<Symbol>] the array of DRI::Documentation properties
      def documentation_properties
        [:creator, :title, :subject, :description, :contributor, :publisher,
         :language, :date, :source, :geographical_coverage, :temporal_coverage,
         :temporal_coverage_period, :creation_date, :published_date,
         :resource_type, :format, :coverage, :rights, :identifier,
         :geocode_point, :geocode_box, :relation]
      end

      # Creates an array of all names stored in the metadata
      def person_array
        people = contributor | publisher
        people |= creator.reject { |c| /^null$/i.match(c) }

        DRI::Vocabulary.marc_relators.each { |role| people |= send("role_#{role}") }

        people
      end

      # Returns the array of types from metadata
      # @return [Array] array of type values from metadata
      def type
        resource_type
      end

      # Remove null values from a given field within
      # the solr document for this object
      #
      # @param [Hash] solr_doc the solr document hash
      # @param [String] field the solr field key
      # @return [hash] the solr document hash
      def remove_null_values(solr_doc, field)
        index_types = [:stored_searchable, :facetable]
        index_types.each do |type|
          if solr_doc[ActiveFedora.index_field_mapper.solr_name(field, type)].present?
            solr_doc[ActiveFedora.index_field_mapper.solr_name(field, type)].delete_if { |v| /^null$/i.match(v) || (!v.nil? && v.empty?) }
          end
        end

        solr_doc
      end

      # Implement additional DRI metadata validations as this class does not inherit
      # from DRI::Metadata::Base
      # @return [Hash] the hash with any errors from validation
      def custom_validations
        errors = {}

        title_result = false
        description_result = false
        rights_result = false
        type_result = false
        date_result = false

        title.each { |t| title_result = true unless t.blank? }
        description.each { |d| description_result = true unless d.blank? }
        rights.each { |r| rights_result = true unless r.blank? }
        resource_type.each { |t| type_result = true unless t.blank? }

        date.each { |d| date_result = true unless d.blank? }
        creation_date.each { |d| date_result = true unless d.blank? } unless date_result
        published_date.each { |d| date_result = true unless d.blank? } unless date_result

        errors[:title] = "can\'t be blank" if title_result == false
        errors[:description] = "can\'t be blank" if description_result == false
        errors[:rights] = "can\'t be blank" if rights_result == false
        errors[:resource_type] = "can\'t be blank" if type_result == false
        errors[:date] = "can\'t be blank" if date_result == false

        errors
      end # custom_validations

      # Override from ActiveFedora::RDFXMLDatastream
      def apply_prefix(name, _file_path)
        "#{name}"
      end
    end
  end
end
