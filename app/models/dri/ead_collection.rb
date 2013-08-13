module DRI
  module Model
    class EADCollection < DigitalObject
      include Hydra::ModelMethods

      has_metadata :name => "descMetadata", :type => DRI::Metadata::EncodedArchivalDescription
      has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata
      has_metadata :name => "defaultRights", :type => Hydra::Datastream::InheritableRightsMetadata

      after_create :apply_default_permissions

      has_many :governed_items, :property => :is_governed_by, :inbound => true, :class_name => "DRI::Metadata::EADComponent"
      
      delegate :title, :to => :descMetadata, :unique=>"true"
      delegate :description, :to => :descMetadata, :unique=>"true"
      delegate :publisher, :to => :descMetadata, :unique=>"true"

      validates :title, :presence=>true

      # Applies default permissions for user types archivist, reviewer, donor and public 
      # 
      def apply_default_permissions
        self.datastreams["rightsMetadata"].update_permissions( "group"=>{"registered"=>"read"} )
        self.datastreams["rightsMetadata"].update_permissions( "group"=>{"public"=>"search"} )
        self.datastreams["rightsMetadata"].private_metadata="0"
        self.datastreams["rightsMetadata"].master_file="1"
        self.save
      end

    end
  end
end
