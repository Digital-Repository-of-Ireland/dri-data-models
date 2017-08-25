# DRI namespace
module DRI
  # Implementation of DRI Documentation digital objects
  # extending from DRI::Base
  class Documentation < DRI::DigitalObject
    # Override DRI::ModelSupport::Base definition of descMetadata
    has_one :descMetadata, class_name: 'DRI::Metadata::QualifiedDublinCore', as: :describable, autosave: true

    # one-to-one AF association to DRI::Base (documentation for)
    belongs_to :documentation_for, class_name: 'DRI::DigitalObject', polymorphic: true

    # Accessors for DRI's metadata terms specific to
    # DRI::Documentation digital objects (based on QDC)
    delegate :date,:date=, to: :descMetadata
    delegate :source,:source=, to: :descMetadata
    delegate :geographical_coverage,:geographical_coverage=, to: :descMetadata
    delegate :temporal_coverage,:temporal_coverage=, to: :descMetadata
    delegate :temporal_coverage_period,:temporal_coverage_period=, to: :descMetadata
    delegate :resource_type,:resource_type=, to: :descMetadata
    delegate :format,:format=, to: :descMetadata
    delegate :coverage,:coverage=, to: :descMetadata
    delegate :identifier,:identifier=, to: :descMetadata
    delegate :geocode_point,:geocode_point=, to: :descMetadata
    delegate :geocode_box,:geocode_box=, to: :descMetadata
    delegate :relation,:relation=, to: :descMetadata

    delegate :published_date,:published_date=, to: :descMetadata
    delegate :creation_date,:creation_date=, to: :descMetadata

    #
    class_eval do
      DRI::Vocabulary.marc_relators.map do |s|
        delegate s.prepend('role_').to_sym,s.concat('=').to_sym,
                 to: :descMetadata
      end
    end

    def declared_attached_files
      { descMetadata: descMetadata, properties: properties }
    end

    def descMetadata
      super || build_descMetadata
    end

    # Override - ingest from RDF-XML files not supported
    # for DRI::Documentation objects
    def update_metadata(_xml_text, _ingest = true) end

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

      # Adding :temporal_coverage_period to properties
      # if :temporal_coverage present
      # for temporal indexing
      if updated_props[:temporal_coverage].present?
        updated_props[:temporal_coverage].each do |item|
          next unless DRI::Metadata::Transformations.dcmi_period?(item)

          period_hash[:temporal_coverage_period] << item
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

    # Retrieve an existing Fedora DRI::Documentation object;
    # creates a new one if object not found for a given PID
    #
    # @param [String] pid the object's PID
    # @return [DRI::Documentation] the retrieved Fedora object; new object if not found
    def self.find_or_create(pid)
      DRI::Documentation.find(pid)
    rescue ActiveRecord::RecordNotFound
      DRI::Documentation.create(id: pid)
    end

    # Override from DRI::Base, default AF method
    def to_solr(solr_doc = {}, opts = {})
      solr_doc = super(solr_doc, opts)

      if documentation_for
        solr_doc.merge!(
          ActiveFedora.index_field_mapper.solr_name(ActiveFedora::RDF::Fcrepo::RelsExt.isDescriptionOf, :symbol) => [documentation_for.id]
        )
      end

      solr_doc
    end

    # Override from DRI::ModelSupport::Base:
    # descMetadata doesn't inherit from base
    # and it loads the correct class
    def load_attributes
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
