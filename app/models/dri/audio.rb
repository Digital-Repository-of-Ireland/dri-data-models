# app/models/audio.rb
# a Fedora object for the Audio hydra content type
require 'active_fedora'
require 'hydra'

module DRI
  module Model
  class Audio < ActiveFedora::Base
    include Hydra::ModelMethods
    #include Hydra::ModelMixins::CommonMetadata
 
    # These will need to be included to avoid deprecation warnings is later versions of HH
    include ActiveFedora::Relationships

    # after_create :apply_default_permissions

    # Set our descriptive metadata datastream
    has_metadata :name => "descMetadata", :type=> DRI::Metadata::DublinCoreAudio 

    # Stick with the default Hydra rights for now
    has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

    #self.ds_specs['masterContent'] = {:type => ActiveFedora::Datastream, :label=>"Master Audio File", :control_group=>'X', :url=>"http://www.google.com/"}

    # has_file_datastream :name => 'masterContent', :type => ActiveFedora::Datastream, :label=>"Master Audio File", :control_group=>'X', :url=>"http://www.google.com/"

    # The delegate method allows you to set up attributes on the model that are stored in datastreams
    # When you set :unique=>"true", searches will return a single value instead of an array.
    delegate :title, :to=>"descMetadata", :unique=>"true"
    delegate :description, :to=>"descMetadata", :unique=>"true"
    delegate :person, :to=>"descMetadata"
    delegate :language, :to=>"descMetadata", :unique=>"true"
    delegate :presenter, :to=>"descMetadata"
    delegate :guest, :to=>"descMetadata"
    delegate :broadcast_date, :to=>"descMetadata", :unique=>"true"
    delegate :subject, :to=>"descMetadata"
    delegate :source, :to=>"descMetadata"

    # Add an URL reference to the master audio file to the Fedora digital object.
    # (this method will be reworked for inclusion with all DRI models)
    #
    # @param [dsid] The id for the new datastream
    # @param [Hash] opts options: :mimeType, :url
    def add_file_reference(dsid, opts={})
      if dsid != "masterContent"
        return false
      end

      file_referenced = false

      if opts.has_key?(:url) 
        attrs = {:label => "Master Audio File", :controlGroup => 'R', :url => opts[:url]}
        if opts.has_key?(:mimeType)
          attrs.merge!({:mimeType=>opts[:mimeType]})
        end
        ds = create_datastream(self.class.datastream_class_for_name(dsid), dsid, attrs)
        add_datastream(ds)
        ds.dsLocation = opts[:url]
        file_referenced = true
      end

      return file_referenced
    end

    # def apply_depositor_metadata(depositor_id)
    #   self.depositor = depositor_id
    #     super
    # end

    #def apply_default_permissions
    #  self.datastreams["rightsMetadata"].update_permissions( "group"=>{"archivist"=>"edit"} )
    #  self.datastreams["rightsMetadata"].update_permissions( "group"=>{"reviewer"=>"edit"} )
    #  self.datastreams["rightsMetadata"].update_permissions( "group"=>{"donor"=>"read"} )
    #  self.datastreams["rightsMetadata"].update_permissions( "group"=>{"public"=>"read"} )
    #end

    def to_solr(solr_doc=Hash.new)
      super(solr_doc)
      solr_doc.merge!(:object_type_facet => "Audio")
      solr_doc
    end

  end
  end
end
