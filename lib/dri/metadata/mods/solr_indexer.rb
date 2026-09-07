module DRI
  module Metadata
    class Mods < DRI::Datastreams::OmDatastream
      # Builds the Solr document hash from a Mods datastream's metadata.
      #
      class SolrIndexer
        include DRI::Metadata::CommonIndexing

        def initialize(datastream)
          @datastream = datastream
        end

        def build(solr_doc)
          solr_doc = index_title_sorted!(solr_doc)
          solr_doc = index_type!(solr_doc)
          solr_doc = index_person!(solr_doc)
          solr_doc = index_all_metadata!(solr_doc)
          solr_doc = index_subject!(solr_doc)
          solr_doc = index_external_relationships!(solr_doc)
          solr_doc = index_dates!(solr_doc)
          solr_doc = index_date_ranges!(solr_doc)
          solr_doc = index_geospatial!(solr_doc)

          solr_doc
        end

        private

        attr_reader :datastream

        # CommonIndexing#all_metadata_text calls a bare ng_xml, so it
        # resolves against whatever includes it. This class doesn't have
        # its own XML - it delegates to the datastream's.
        def ng_xml
          datastream.ng_xml
        end

        def index_title_sorted!(solr_doc)
          return solr_doc if datastream.title.empty?

          sorted_title = DRI::Metadata::Transformations.transform_title_for_sort(datastream.title[0])
          solr_doc['title_sorted_ssi'] = [sorted_title] unless sorted_title.empty?

          solr_doc
        end

        def index_type!(solr_doc)
          type_for_index = datastream.type_of_resource
          solr_doc['type_tesim'] = type_for_index
          solr_doc['type_sim'] = type_for_index
          solr_doc['type_tesim'] = 'Collection' if datastream.collection?

          solr_doc
        end

        # MODS has several "name" tags, so we merge them together into the SOLR document
        def index_person!(solr_doc)
          person_array = datastream.person_array_for_index

          solr_doc['person_sim'] = person_array
          solr_doc['person_tesim'] = person_array | DRI::Metadata::Transformations.transform_name(person_array)

          solr_doc
        end

        # all_metadata - A SOLR index of all the text contained in the XML document
        def index_all_metadata!(solr_doc)
          solr_doc['all_metadata_tesim'] = [all_metadata_text]
          solr_doc
        end

        def index_subject!(solr_doc)
          solr_doc['subject_tesim'] = datastream.subject unless datastream.subject.empty?
          solr_doc['subject_sim'] = datastream.subject unless datastream.subject.empty?

          unless datastream.name_coverage.empty?
            names = datastream.subject_name_for_index
            solr_doc['name_coverage_tesim'] = names
            solr_doc['name_coverage_sim'] = names
          end

          subject_place_array = datastream.subject_place_for_index
          unless subject_place_array.empty?
            solr_doc['geographical_coverage_tesim'] = subject_place_array
            solr_doc['geographical_coverage_sim'] = datastream.filter_uris(subject_place_array)
          end

          subject_temporal_array = datastream.subject_temporal_for_index
          unless subject_temporal_array.empty?
            solr_doc['temporal_coverage_tesim'] = subject_temporal_array
            solr_doc['temporal_coverage_sim'] = datastream.filter_uris(subject_temporal_array)
          end

          solr_doc
        end

        # Indices for external relationships (to be displayed as URL)
        def index_external_relationships!(solr_doc)
          external_rels = DRI::Vocabulary.mods_relationship_types.map { |s| :"ext_related_items_ids_#{s}" }

          external_rels.each do |elem|
            values = datastream.send(elem)
            solr_doc["#{elem}_tesim"] = values unless values == []
          end

          solr_doc
        end

        def index_dates!(solr_doc)
          solr_doc['creation_date_tesim'] = datastream.creation_date_for_index
          solr_doc['date_tesim'] = datastream.date_for_index

          unless datastream.published_date.empty? && datastream.issued_date_start.empty?
            solr_doc['published_date_tesim'] = datastream.display_single_date_for_index(datastream.published_date) |
                                                datastream.display_date_range_for_index(datastream.issued_date_start, datastream.issued_date_end)
          end

          solr_doc
        end

        # Index date ranges. dateRangeField is defined in Solr's schema.xml
        # as a field of type date_range (solr.SpatialRecursivePrefixTreeFieldType)
        def index_date_ranges!(solr_doc)
          date_ranges = datastream.date_ranges_for_index # ALL the date ranges

          index_date_range!(solr_doc, transformed(date_ranges, 'creation_date', 'captured_date'),
                             range_field: DRI::Metadata::Transformations::CREATION_DATE_RANGE_SOLR_FIELD,
                             year_field: DRI::Metadata::Transformations::CREATION_DATE_YEAR_SOLR_FIELD,
                             start_field: DRI::Metadata::Transformations::CREATION_DATE_RANGE_START_SOLR_FIELD,
                             end_field: DRI::Metadata::Transformations::CREATION_DATE_RANGE_END_SOLR_FIELD)

          index_date_range!(solr_doc, transformed(date_ranges, 'issued_date'),
                             range_field: DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_SOLR_FIELD,
                             year_field: DRI::Metadata::Transformations::PUBLISHED_DATE_YEAR_SOLR_FIELD,
                             start_field: DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_START_SOLR_FIELD,
                             end_field: DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_END_SOLR_FIELD)

          index_date_range!(solr_doc, transformed(date_ranges, 'date_other', 'part_date'),
                             range_field: DRI::Metadata::Transformations::DATE_RANGE_SOLR_FIELD,
                             start_field: DRI::Metadata::Transformations::DATE_RANGE_START_SOLR_FIELD,
                             end_field: DRI::Metadata::Transformations::DATE_RANGE_END_SOLR_FIELD)

          index_date_range!(solr_doc, transformed(date_ranges, 'subject_date'),
                             range_field: DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_SOLR_FIELD,
                             start_field: DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_START_SOLR_FIELD,
                             end_field: DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_END_SOLR_FIELD)

          solr_doc
        end

        # Selects the requested keys out of date_ranges_for_index's hash and
        # transforms them - CommonIndexing#index_date_range! expects an
        # already-transformed ranges array, not a raw dates hash.
        def transformed(date_ranges, *keys)
          selected = date_ranges.select { |key, _value| keys.include?(key) }
          DRI::Metadata::Transformations.transform_date_ranges(selected)
        end

        # Index dcterms Point and Box data, and linked data uris into geospatial Solr field
        def index_geospatial!(solr_doc)
          geospatial_hash = DRI::Metadata::Transformations.transform_geospatial(
            'geographical_coverage' => datastream.geographical_coverage.reject { |i| i[/\A#{URI.regexp(['http', 'https'])}\z/] }
          )

          # Index logainm URIs in the appropriate geographic indices
          uris = datastream.geocode_logainm.select { |i| i[/\A#{URI.regexp(['http', 'https'])}\z/] } | datastream.reconciliation_uris
          if uris.present?
            linked_data = DRI::Metadata::Transformations.transform_geospatial('geographical_coverage' => uris)

            geospatial_hash[:coords].concat(linked_data[:coords])
            geospatial_hash[:name].concat(linked_data[:name])
            geospatial_hash[:json].concat(linked_data[:json])
          end

          solr_doc[DRI::Metadata::Transformations::GEOSPATIAL_SOLR_FIELD] = geospatial_hash[:coords] if geospatial_hash[:coords].present?

          unless geospatial_hash[:name].empty?
            solr_doc["#{DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD}_tesim"] = geospatial_hash[:name]
            solr_doc["#{DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD}_sim"] = geospatial_hash[:name]
          end

          solr_doc[DRI::Metadata::Transformations::GEOJSON_SOLR_FIELD] = geospatial_hash[:json] if geospatial_hash[:json].present?

          solr_doc
        end
      end
    end
  end
end
