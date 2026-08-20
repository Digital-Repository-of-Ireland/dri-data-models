# frozen_string_literal: true
# DRI namespace
module DRI
  # Implementation of DRI Documentation digital objects
  class Documentation < DRI::DigitalObject
    has_one :descMetadata, class_name: 'DRI::Metadata::QualifiedDublinCore', as: :describable, autosave: true

    # one-to-one AF association to DRI::DigitalObject (documentation for)
    belongs_to :documentation_for, polymorphic: true

    # Accessors for DRI's metadata terms specific to
    # DRI::Documentation digital objects (based on QDC)
    delegate :date, :date=, to: :descMetadata
    delegate :source, :source=, to: :descMetadata
    delegate :geographical_coverage, :geographical_coverage=, to: :descMetadata
    delegate :temporal_coverage, :temporal_coverage=, to: :descMetadata
    delegate :resource_type, :resource_type=, to: :descMetadata
    delegate :format, :format=, to: :descMetadata
    delegate :coverage, :coverage=, to: :descMetadata
    delegate :identifier, :identifier=, to: :descMetadata
    delegate :geocode_point, :geocode_point=, to: :descMetadata
    delegate :geocode_box, :geocode_box=, to: :descMetadata
    delegate :relation, :relation=, to: :descMetadata
    delegate :access_rights, :access_rights=, to: :descMetadata

    delegate :published_date, :published_date=, to: :descMetadata
    delegate :creation_date, :creation_date=, to: :descMetadata

    class_eval do
      DRI::Vocabulary.marc_relators.map do |s|
        delegate s.prepend('role_').to_sym, s.concat('=').to_sym,
                 to: :descMetadata
      end
    end

    def declared_attached_files
      { descMetadata: descMetadata }
    end

    def descMetadata
      super || build_descMetadata
    end

    # AF Override
    # Set the object's attributes
    # @param [Hash] properties the hash with the object's properties
    def attributes=(properties)
      updated_props = properties.clone
      point_hash = { geocode_point: [] }
      box_hash = { geocode_box: [] }
      period_hash = { temporal_coverage_period: [] }

      # When updating from DRI form
      # replace type attribute key with resource_type
      updated_props[:resource_type] = updated_props.delete :type

      # Adding :geocode_point and :geocode_box to properties
      # if :geographical_coverage present
      # for spatial indexing
      if updated_props[:geographical_coverage].present?
        updated_props[:geographical_coverage].each do |item|
          point_hash[:geocode_point] << item if DRI::Metadata::Transformations.dcmi_point?(item)
          box_hash[:geocode_box] << item if DRI::Metadata::Transformations.dcmi_box?(item)
        end
      end

      # avoid overwriting entries with duplicate keys
      updated_props.merge!(point_hash) { |_k, v0, _v2| v0 } if point_hash[:geocode_point].present?
      updated_props.merge!(box_hash) { |_k, v0, _v2| v0 } if box_hash[:geocode_box].present?
      updated_props.merge!(period_hash) { |_k, v0, _v2| v0 } if period_hash[:temporal_coverage_period].present?

      super(updated_props)
    end

    # Roles attribute setter
    #
    # @param [Hash] roles hash with metadata marcrelator values
    # @option roles [Array<String>] :name the metadata values for the marcrelators in :type
    # @option roles [Array<String>] :type the marcrelator codes
    def roles=(roles)
      descMetadata.roles = roles if descMetadata.is_a? DRI::Metadata::QualifiedDublinCore
    end

    # Type attribute getter
    #
    # @return [Array<String>] the array of metadata type values
    def type
      descMetadata.resource_type
    end

    # Type attribute setter
    # @param [Array<String>] type the array of metadata type values to set
    def type=(type)
      descMetadata.resource_type = type
    end

    # Override from DRI::ModelSupport::Base
    # Documentation does not inherit from DRI::Metadata::Base
    # Perform additional DRI validations before saving the object
    def custom_validations
      results = descMetadata.custom_validations
      return true if results.empty?

      results.each { |key, value| errors.add(key, value) }

      false
    end # custom_validations
  end
end
