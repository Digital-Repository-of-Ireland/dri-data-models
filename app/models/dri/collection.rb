module DRI
  module Model
    class Collection < ActiveFedora::Base
      include Hydra::ModelMethods
      include Hydra::ModelMixins::RightsMetadata

      has_metadata :name => "descMetadata", :type => DRI::Metadata::DublinCoreCollection
      has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata
      has_metadata :name => "defaultRights", :type => Hydra::Datastream::InheritableRightsMetadata
      has_metadata :name => "properties", :type => DRI::Metadata::Properties

      has_many :governed_items, :property => :is_governed_by, :inbound => true, :class_name => "ActiveFedora::Base"
      has_many :items, :property => :is_member_of_collection, :inbound => true, :class_name => "ActiveFedora::Base"

      delegate :title, :to => :descMetadata, :unique=>"true"
      delegate :description, :to => :descMetadata, :unique=>"true"
      delegate :publisher, :to => :descMetadata, :unique=>"true"

      delegate :depositor, :to=> :properties, :unique=>"true"
      delegate :model_version, :to=>"properties", :unique=>"true"

      delegate :status, :to=>"properties", :unique=>"true"

      validates :title, :presence=>true

      # Applies default permissions
      #
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
