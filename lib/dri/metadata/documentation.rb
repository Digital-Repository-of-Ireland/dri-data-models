module DRI
  module Metadata
    class Documentation < ActiveFedora::RDFXMLDatastream
      # Versionable, included as this DS does not inherit from DRI::MetadataBase
      # has_many_versions

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
                 DRI::Metadata::Descriptors.cleaned_facetable,
                 DRI::Metadata::Descriptors.cleaned_displayable
      end

      property :geocode_point, predicate: RDF::DC.Point

      property :geocode_box, predicate: RDF::DC.Box

      property :temporal_coverage_period, predicate: RDF::DC.Period

      property :relation, predicate: RDF::DC.relation do |index|
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

      def collection?
        false
      end

      # Implement this method as implemented also in DRI::Metadata::Base
      def to_xml
        serialize
      end

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

      def to_solr(solr_doc = {}, opts = {})
        solr_doc = super(solr_doc, opts)

        # Index dates here, for display
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('creation_date', :stored_searchable) => display_date_for_index(creation_date))
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('published_date', :stored_searchable) => display_date_for_index(published_date))
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('temporal_coverage', :stored_searchable) => display_date_for_index(temporal_coverage_period) | display_date_for_index(date))
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('date', :stored_searchable) => display_date_for_index(date))

        solr_doc = remove_null_values(solr_doc, 'creation_date') if solr_doc[ActiveFedora::SolrQueryBuilder.solr_name('creation_date', :stored_searchable)].present?
        solr_doc = remove_null_values(solr_doc, 'published_date') if solr_doc[ActiveFedora::SolrQueryBuilder.solr_name('published_date', :stored_searchable)].present?
        solr_doc = remove_null_values(solr_doc, 'date') if solr_doc[ActiveFedora::SolrQueryBuilder.solr_name('date', :stored_searchable)].present?
        solr_doc = remove_null_values(solr_doc, 'temporal_coverage') if solr_doc[ActiveFedora::SolrQueryBuilder.solr_name('temporal_coverage', :stored_searchable)].present?
        solr_doc = remove_null_values(solr_doc, 'creator') if solr_doc[ActiveFedora::SolrQueryBuilder.solr_name('creator', :stored_searchable)].present?

        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('type', :stored_searchable) => resource_type)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('type', :facetable) => resource_type)

        # Retrieve list of all people and add them to facet and search indexes in solr document
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('person', :facetable) => person_array)
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('person', :stored_searchable, type: :text) => person_array | DRI::Metadata::Transformations.transform_name(person_array))

        # title_sorted - A SOLR index for sorting titles
        unless title.empty?
          sorted_title = DRI::Metadata::Transformations.transform_title_for_sort(title[0])
          unless sorted_title.empty?
            solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('title_sorted', :stored_sortable, type: :string) => [sorted_title])
          end
        end

        # all_metadata
        # SOLR index of all text nodes in the XML document
        all_metadata = ''

        documentation_properties.each do |property|
          all_metadata += get_values(property).join(' ')
          all_metadata += ' '
        end
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('all_metadata', :stored_searchable, type: :text) => [all_metadata])

        # dateRangeField is defined in Solr's schema.xml
        # as a field of type date_range
        # (solr.SpatialRecursivePrefixTreeFieldType)
        cdate_ranges = DRI::Metadata::Transformations.transform_date_ranges({ 'creation_date' => creation_date })
        pdate_ranges = DRI::Metadata::Transformations.transform_date_ranges({ 'published_date' => published_date })
        sdate_ranges = DRI::Metadata::Transformations.transform_date_ranges({ 'date' => date, 'temporal_coverage' => temporal_coverage | temporal_coverage_period })

        solr_doc.merge!(DRI::Metadata::Transformations::CREATION_DATE_RANGE_SOLR_FIELD => cdate_ranges) unless cdate_ranges.empty?
        solr_doc.merge!(DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_SOLR_FIELD => pdate_ranges) unless pdate_ranges.empty?
        solr_doc.merge!(DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_SOLR_FIELD => sdate_ranges) unless sdate_ranges.empty?

        # Index dcterms Point and Box data into geospatial Solr field (location_rpt)
        geospatial_hash = DRI::Metadata::Transformations.transform_geospatial({ 'geographical_coverage' => geocode_point | geocode_box })

        uris = geographical_coverage.select { |i| i[/\A#{URI.regexp(['http', 'https'])}\z/] }
        if uris.present?
          linked_data = DRI::Metadata::Transformations.transform_geospatial({ 'geographical_coverage' => uris })

          geospatial_hash[:coords].concat(linked_data[:coords])
          geospatial_hash[:name].concat(linked_data[:name])
          geospatial_hash[:json].concat(linked_data[:json])
        end

        solr_doc.merge!(DRI::Metadata::Transformations::GEOSPATIAL_SOLR_FIELD => geospatial_hash[:coords]) if geospatial_hash[:coords].present?
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name(DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD, :stored_searchable) => geospatial_hash[:name]) if geospatial_hash[:name].present?
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name(DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD, :facetable, type: :text) => geospatial_hash[:name]) if geospatial_hash[:name].present?
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('geojson', :stored_searchable, type: :symbol) => geospatial_hash[:json]) if geospatial_hash[:json].present?

        solr_doc
      end

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
              sdate = ISO8601::DateTime.new(value).strftime('%Y-%m-%d')
              DRI::Metadata::Transformations.create_dcmi_period(value, sdate)
            end
          rescue ISO8601::Errors::StandardError
            # DCMI Period 'name' is the md value
            DRI::Metadata::Transformations.create_dcmi_period(value)
          end
        end
      end

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

      def type
        resource_type
      end

      def remove_null_values(solr_doc, field)
        index_types = [:stored_searchable, :facetable]
        index_types.each do |type|
          if solr_doc[ActiveFedora::SolrQueryBuilder.solr_name(field, type)].present?
            solr_doc[ActiveFedora::SolrQueryBuilder.solr_name(field, type)].delete_if { |v| /^null$/i.match(v) || (!v.nil? && v.empty?) }
          end
        end

        solr_doc
      end

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

      def apply_prefix(name, _file_path)
        "#{name}"
      end
    end
  end
end
