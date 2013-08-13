module DRI
  module Model

    class DigitalObject < ActiveFedora::Base
      include Hydra::ModelMethods
      include Hydra::ModelMixins::RightsMetadata
      include ActiveFedora::Auditable
      
      #belongs_to :collection, :property => :is_member_of, :class_name => 'DRI::Model::Collection'

      #after_create :apply_default_permissions 

      # Stick with the default Hydra rights for now
      has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

      has_metadata :name => "properties", :type => DRI::Metadata::Properties

      def DigitalObject.construct(type, params)
        { :audio => Audio, :pdfdoc => Pdfdoc }[type].new(params)
      end

      # Applies default permissions for user types archivist, reviewer, donor and public 
      # 
      def apply_default_permissions
        self.datastreams["rightsMetadata"].update_permissions( "group"=>{"archivist"=>"edit"} )
        self.datastreams["rightsMetadata"].update_permissions( "group"=>{"reviewer"=>"edit"} )
        self.datastreams["rightsMetadata"].update_permissions( "group"=>{"donor"=>"read"} )
        self.datastreams["rightsMetadata"].update_permissions( "group"=>{"public"=>"read"} )
        self.save
      end

      def self.apply_properties_delegates
        delegate :status, :to=>"properties", :unique=>"true"
        delegate :object_type, :to=>"properties", :unique=>"true"
        delegate :depositor, :to=>"properties", :unique=>"true"
        delegate :metadata_md5, :to=>"properties", :unique=>"true"
        delegate :model_version, :to=>"properties", :unique=>"true"
        delegate :metadata_md5, :to=>"properties", :unique=>"true"
        delegate :verified, :to=>"properties", :unique=>"true"
        delegate :resource, :to=>"properties"
        delegate :resource_datastream, :to=>"properties" 
        delegate :resource_md5, :to=>"properties"
        delegate :resource_sha256, :to=>"properties"
        delegate :resource_rmd160, :to=>"properties"
      end


      # Override save to add a default language of "en" if not set in the xml file
      #
      # There does not seem to be a better way to do this
      #
      def save
        super
        self.language ||= "en"

      end

      # Add default system properties
      apply_properties_delegates
    end

  end
end 
