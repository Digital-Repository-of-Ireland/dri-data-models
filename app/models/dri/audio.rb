# app/models/audio.rb
# a Fedora object for the Audio hydra content type

module DRI
  module Model
  class Audio < DigitalObject

    # Whitelist of allowed mime-types for audio files
    @@wl_type = "audio"
    @@wl_subtypes = ["mp3","mpeg","mpeg3","mp2"]

    @@mime_type = "audio/*"

    # Set relationships rules
    belongs_to :governing_collection, :property=>:is_governed_by, :class_name => 'DRI::Model::Collection'
    has_many :collections, :property=>:is_member_of_collection, :class_name => 'DRI::Model::Collection'

    # Set our descriptive metadata datastream
    has_metadata :name => "descMetadata", :type=> DRI::Metadata::DublinCoreAudio 

    # The delegate method allows you to set up attributes on the model that are stored in datastreams
    # When you set :unique=>"true", searches will return a single value instead of an array.
    delegate :title, :to=>"descMetadata", :unique=>"true"
    delegate :description, :to=>"descMetadata", :unique=>"true"
    delegate :language, :to=>"descMetadata", :unique=>"true"
    delegate :presenter, :to=>"descMetadata"
    delegate :producer, :to=>"descMetadata"
    delegate :guest, :to=>"descMetadata"
    delegate :broadcast_date, :to=>"descMetadata", :unique=>"true"
    delegate :creation_date, :to=>"descMetadata", :unique=>"true"
    delegate :subject, :to=>"descMetadata"
    delegate :source, :to=>"descMetadata"
    delegate :geographical_coverage, :to=>"descMetadata"
    delegate :temporal_coverage, :to=>"descMetadata"
    delegate :rights, :to=>"descMetadata", :unique=>"true"
    apply_properties_delegates

    # Validate presence of level 1 attributes title and rights (type is added automatically)
    validates :title, :presence=>true
    validates :rights, :presence=>true
    validates :language, :presence=>true # language should be set automatically if not passed in, so should always be present

    # Add an URL reference to the master audio file to the Fedora digital object.
    # (this method will be reworked for inclusion with all DRI models)
    #
    # @param [dsid] The id for the new datastream
    # @param [Hash] opts options: :mimeType, :url
    def add_file_reference(dsid, opts={})
      if !["masterContent","mp3Surrogate","oggSurrogate"].include?(dsid)
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

    # Calls the ActiveFedora to_solr method 
    #
    def to_solr(solr_doc=Hash.new)
      super(solr_doc)

      # Add title metadata from parent collections
      collection_titles = []
      if (governing_collection != nil)
        collection_titles = [governing_collection.title]
      end
      collections.each do |coll|
        collection_titles | coll.title
      end
      if (!collection_titles.empty?)
        solr_doc.merge!(solr_name('collection', :facetable) => collection_titles)
        solr_doc.merge!(solr_name('collection', :stored_searchable) => collection_titles)
      end

      solr_doc.merge!(solr_name('object_type', :stored_searchable) => "Audio")
      solr_doc.merge!(solr_name('object_type', :facetable) => "Audio")
      solr_doc
    end

    # Create datastream from xml
    #
    def load_from_xml(xml)
      DRI::Metadata::DublinCoreAudio.from_xml(xml)
    end

    # Return the whitelisted type for this class
    def whitelist_type
      return @@wl_type
    end

    # Return a list of whitelisted subtypes for this class
    def whitelist_subtypes
      return @@wl_subtypes
    end

    #Return the mime type for this object
    def mime_type
      return @@mime_type
    end

  end
  end
end
