module DRI
  module Model
    class Collection < ActiveFedora::Base
      include Hydra::ModelMethods
      include ActiveFedora::Relationships

      has_metadata :name => "descMetadata", :type => DRI::Metadata::CollectionMetadata
      has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

      after_create :apply_default_permissions

      has_relationship("objects", :is_member_of, :inbound=>true)

      delegate :title, :to => :descMetadata, :unique=>"true"
      delegate :creator, :to => :descMetadata, :unique=>"true"
      delegate :part, :to => :descMetadata
      delegate :description, :to => :descMetadata, :unique=>"true"

      # Applies default permissions for user types archivist, reviewer, donor and public 
      # 
      def apply_default_permissions
        self.datastreams["rightsMetadata"].update_permissions( "group"=>{"archivist"=>"edit"} )
        self.datastreams["rightsMetadata"].update_permissions( "group"=>{"reviewer"=>"edit"} )
        self.datastreams["rightsMetadata"].update_permissions( "group"=>{"donor"=>"read"} )
        self.datastreams["rightsMetadata"].update_permissions( "group"=>{"public"=>"read"} )
        self.save
     end 

    end
  end
end
