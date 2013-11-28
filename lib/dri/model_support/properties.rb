module DRI
  module ModelSupport
  	module Properties
      extend ActiveSupport::Concern

      included do
      	has_metadata :name => "properties", :type => DRI::Metadata::Properties

        has_attributes :status, datastream: :properties, multiple: false
        has_attributes :object_type, datastream: :properties, multiple: true
        has_attributes :depositor, datastream: :properties, multiple: false
        has_attributes :metadata_md5, datastream: :properties, multiple: false
        has_attributes :model_version, datastream: :properties, multiple: false
        has_attributes :verified, datastream: :properties, multiple: false 
      end
    end
  end
end