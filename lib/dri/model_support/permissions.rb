module DRI
  module ModelSupport
  	module Permissions
      extend ActiveSupport::Concern

      included do
      	include Hydra::ModelMixins::RightsMetadata

        has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata   
      end

      def apply_default_permissions
        self.datastreams["rightsMetadata"].update_permissions( "group"=>{"registered"=>"read"} )
        self.datastreams["rightsMetadata"].update_permissions( "group"=>{"public"=>"discover"} )
        self.datastreams["rightsMetadata"].private_metadata="0"
        self.datastreams["rightsMetadata"].master_file="1"
        self.save
      end
    end
  end
end
