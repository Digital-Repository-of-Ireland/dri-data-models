module DRI
  module Metadata
    class Mods < DRI::Datastreams::OmDatastream
      # Runs the additional DRI validations Mods needs, since it doesn't
      # inherit from DRI::Metadata::Base.
      class Validator
        DATE_PRESENCE_FALLBACK_FIELDS = %i[
          creation_date_start published_date issued_date_start captured_date
          captured_date_start other_date other_date_start
        ].freeze

        def initialize(datastream)
          @datastream = datastream
        end

        # @return [Hash] the hash with any errors from validation
        def call
          errors = {}

          errors[:mods_id_local] = 'not present.' unless metadata_present?(datastream.mods_id_local)
          errors[:identifier_uri] = 'invalid URI present' unless all_valid_uris?(datastream.identifier_uri)
          # Check that for external relationships terms, the specified URIs are valid
          errors[:related_items_digital] = 'invalid URI present' unless all_valid_uris?(datastream.related_items_digital)
          errors[:title] = "can't be blank" unless metadata_present?(datastream.title)
          errors[:type] = "can't be blank" unless type_present?
          errors[:creator] = "can't be blank" unless creator_present?
          errors[:description] = "can't be blank" unless metadata_present?(datastream.description)
          errors[:rights] = "can't be blank" unless metadata_present?(datastream.rights)
          # Creation date can either be: dateCreated, dateIssued, dateCaptured (in this priority order)
          errors[:date] = "can't be blank" unless date_present?

          errors
        end

        private

        attr_reader :datastream

        def metadata_present?(values)
          values.any?(&:present?)
        end

        def all_valid_uris?(values)
          values.all? { |value| value.present? && Utils.valid_uri?(value) }
        end

        def type_present?
          metadata_present?(datastream.resource_type) || metadata_present?(datastream.mods_genre)
        end

        def creator_present?
          return true if metadata_present?(datastream.creator)

          marc_role_fields.any? { |role_field| metadata_present?(datastream.send(role_field)) }
        end

        # Pure vocabulary lookup, not datastream-instance-dependent, so this
        # one doesn't need to go through method_missing.
        def marc_role_fields
          DRI::Vocabulary.marc_relators.map { |role| :"role_#{role}" }
        end

        def date_present?
          return true if metadata_present?(datastream.creation_date)

          DATE_PRESENCE_FALLBACK_FIELDS.any? { |field| metadata_present?(datastream.send(field)) }
        end
      end
    end
  end
end
