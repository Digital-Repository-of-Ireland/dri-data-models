module DRI
  module ModelSupport
    module Properties
      extend ActiveSupport::Concern

      included do
        has_metadata :name => "MARC", :type => DRI::Metadata::Marc

        has_attributes :title, datastream: :descMetadata, multiple: true
        has_attributes :description, datastream: :descMetadata, multiple: true
        has_attributes :language, datastream: :descMetadata, multiple: true
        has_attributes :creator, datastream: :descMetadata, multiple: true
        has_attributes :contributor, datastream: :descMetadata, multiple: true
        has_attributes :publisher, datastream: :descMetadata, multiple: true
        has_attributes :date, datastream: :descMetadata, multiple: true
        has_attributes :published_date, datastream: :descMetadata, multiple: true
        has_attributes :creation_date, datastream: :descMetadata, multiple: true
        has_attributes :relation, datastream: :descMetadata, multiple: true
        has_attributes :subject, datastream: :descMetadata, multiple: true
        has_attributes :source, datastream: :descMetadata, multiple: true
        has_attributes :geographical_coverage, datastream: :descMetadata, multiple: true
        has_attributes :temporal_coverage, datastream: :descMetadata, multiple: true
        has_attributes :rights, datastream: :descMetadata, multiple: true
        has_attributes :type, datastream: :descMetadata, multiple: true
        has_attributes :format, datastream: :descMetadata, multiple: true
        has_attributes :coverage, datastream: :descMetadata, multiple: true
        has_attributes :identifier, datastream: :descMetadata, multiple: true
        has_attributes :geocode_point, datastream: :descMetadata, multiple: true
        has_attributes :geocode_box, datastream: :descMetadata, multiple: true
        has_attributes  *(DRI::Vocabulary::marcRelators.map { |s| s.prepend("role_").to_sym}), datastream: :descMetadata,
                        multiple: true

        has_attributes :abstract, datastream: :descMetadata, multiple: false
        has_attributes :bioghist, datastream: :descMetadata, multiple: false
        has_attributes :scope_content, datastream: :descMetadata, multiple: false
        has_attributes :ead_level, datastream: :descMetadata, multiple: false
        has_attributes :name_coverage, datastream: :descMetadata, multiple: true
        has_attributes :physdesc, datastream: :descMetadata, multiple: true
        has_attributes :dao, datastream: :descMetadata, multiple: true
        has_attributes :dao_href, datastream: :descMetadata, multiple: true
        has_attributes :unitid, datastream: :descMetadata, multiple: false
        has_attributes :repository_code, datastream: :descMetadata, multiple: false
        has_attributes :country_code, datastream: :descMetadata, multiple: false

        has_attributes :datafield_336_ind1__ind2__subfield_a, datastream: :descMetadata, multiple: true
        has_attributes :leader, datastream: :descMetadata, multiple: true

      end
    end
  end
end