module DRI
  module Model
    class Collection < ActiveFedora::Base
      include Hydra::ModelMethods
      include Hydra::ModelMixins::RightsMetadata

      has_metadata :name => "descMetadata", :type => DRI::Metadata::DublinCoreCollection
      has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata
      has_metadata :name => "defaultRights", :type => Hydra::Datastream::InheritableRightsMetadata
      has_metadata :name => "properties", :type => DRI::Metadata::Properties

      after_create :apply_default_permissions

      has_many :governed_items, :property => :is_governed_by, :inbound => true, :class_name => "ActiveFedora::Base"
      has_many :items, :property => :is_member_of_collection, :inbound => true, :class_name => "ActiveFedora::Base"

      delegate :title, :to => :descMetadata, :unique=>"true"
      delegate :description, :to => :descMetadata, :unique=>"true"
      delegate :publisher, :to => :descMetadata, :unique=>"true"

      delegate :depositor, :to=> :properties, :unique=>"true"
      delegate :model_version, :to=>"properties", :unique=>"true"

      validates :title, :presence=>true

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
