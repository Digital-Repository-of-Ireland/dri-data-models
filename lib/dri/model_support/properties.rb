module DRI
  module ModelSupport
  	module Properties
      extend ActiveSupport::Concern

      included do
      	has_metadata :name => "properties", :type => DRI::Metadata::Properties

        delegate :status, :to=>"properties", :unique=>"true"
        delegate :object_type, :to=>"properties"
        delegate :depositor, :to=>"properties", :unique=>"true"
        delegate :metadata_md5, :to=>"properties", :unique=>"true"
        delegate :model_version, :to=>"properties", :unique=>"true"
        delegate :verified, :to=>"properties", :unique=>"true"  
      end
    end
  end
end