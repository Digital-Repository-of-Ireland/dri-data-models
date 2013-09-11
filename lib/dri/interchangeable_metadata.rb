module DRI
  module Model
  	   module InterchangeableMetadata
    extend ActiveSupport::Concern
    
    included do
      attr_accessor :metadata_class

      has_metadata :name => "descMetadata", :type => ActiveFedora::OmDatastream

      after_initialize :load_delegates
    end

    def has_metadata_class_changed?
      if (self.metadata_class != descMetadata.class)
        true
      else
        false
      end
    end

    # Checks to see if the descMetadata class has
    # been swapped out with another OmDatastream class,
    # if so this method will save this ActiveFedora::Base
    # and reload it so that the delegates change to relect
    # the new class
    def save_and_reload_if_metadata_class_changed
      if has_metadata_class_changed?
        self.save
        self.reload
      end
    end

    # Use this in preference over the xml function in OmDatastreams
    def metadata_xml xml_text
      curr_metadata = descMetadata.class

    end

    def get_metadata_class_from_xml xml_text
      result = "ActiveFedora::OmDatastream"

      xml = Nokogiri::XML xml_text

      namespace = xml.namespaces

      if namespace.has_key?("xmlns:dc") && namespace["xmlns:dc"].eql?("http://purl.org/dc/elements/1.1/")
        result = "DRI::Metadata::QualifiedDublinCore"
      end

      if xml.internal_subset.name == 'ead'
        result = "DRI::Metadata::EncodedArchivalDescription"
      end

      root_name = xml.root.name

      if ['c', 'c1', 'c2', 'c3', 'c4', 'c5', 'c6', 'c7', 'c8', 'c9', 'c10', 'c11', 'c12'].include? root_name
        result = "DRI::Metadata::EncodedArchivalDescriptionComponent"
      end

      return result
    end

    def load_delegates
      if datastreams.has_key?("descMetadata")
    
      # If descMetadata is an OmDatastream, then check if we need to replace it with a DRI
      # metadata class
      if descMetadata.class == ActiveFedora::OmDatastream
        ds_class = get_metadata_class_from_xml descMetadata.to_xml

        if ds_class != "ActiveFedora::OmDatastream"
          ds = nil
          if ds_class == "DRI::Metadata::QualifiedDublinCore"
            ds = DRI::Metadata::QualifiedDublinCore.from_xml descMetadata.to_xml
          elsif ds_class == "DRI::Metadata::EncodedArchivalDescription"
            ds = DRI::Metadata::EncodedArchivalDescription.from_xml descMetadata.to_xml
          elsif ds_class == "DRI::Metadata::EncodedArchivalDescriptionComponent"
            ds = DRI::Metadata::EncodedArchivalDescriptionComponent.from_xml descMetadata.to_xml
          end
            
          ds.instance_variable_set :@dsid, "descMetadata"
          self.add_datastream ds
        end
      end

      self.metadata_class = descMetadata.class

      case descMetadata
        when DRI::Metadata::QualifiedDublinCore
          self.class.delegate :title, :to=>"descMetadata", :unique=>"true"
          self.class.delegate :description, :to=>"descMetadata", :unique=>"true"
          self.class.delegate :language, :to=>"descMetadata", :unique=>"true"
          self.class.delegate :creator, :to=>"descMetadata"
          self.class.delegate :contributor, :to=>"descMetadata"
          self.class.delegate :publisher, :to=>"descMetadata"
          self.class.delegate :published_date, :to=>"descMetadata"
          self.class.delegate :creation_date, :to=>"descMetadata", :unique=>"true"
          self.class.delegate :relation, :to=>"descMetadata"
          self.class.delegate :subject, :to=>"descMetadata"
          self.class.delegate :source, :to=>"descMetadata"
          self.class.delegate :geographical_coverage, :to=>"descMetadata"
          self.class.delegate :temporal_coverage, :to=>"descMetadata"
          self.class.delegate :rights, :to=>"descMetadata", :unique=>"true"
          self.class.delegate :type, :to=>"descMetadata", :unique=>"true"
          self.class.delegate :format, :to=>"descMetadata"
          self.class.delegate :coverage, :to=>"descMetadata"
          self.class.delegate :identifier, :to=>"descMetadata"
          self.class.delegate :geocode_point, :to=>"descMetadata"
          self.class.delegate :geocode_box, :to=>"descMetadata"
          self.class.delegate_to :descMetadata, DRI::Vocabulary::marcRelators.map { |s| s.prepend("role_").to_sym}
        when DRI::Metadata::EncodedArchivalDescription
          self.class.delegate :title, :to => :descMetadata, :unique=>"true"
          self.class.delegate :description, :to => :descMetadata, :unique=>"true"
          self.class.delegate :language, :to => :descMetadata
          self.class.delegate :creator, :to => :descMetadata
          self.class.delegate :creation_date, :to => :descMetadata
          self.class.delegate :name_coverage, :to => :descMetadata
          self.class.delegate :geographical_coverage, :to => :descMetadata
        when DRI::Metadata::EncodedArchivalDescriptionComponent
          self.class.delegate :title, :to => :descMetadata, :unique=>"true"
          self.class.delegate :description, :to => :descMetadata, :unique=>"true"
          self.class.delegate :language, :to => :descMetadata
          self.class.delegate :creator, :to => :descMetadata
          self.class.delegate :creation_date, :to => :descMetadata
          self.class.delegate :name_coverage, :to => :descMetadata
          self.class.delegate :geographical_coverage, :to => :descMetadata
          self.class.delegate :unitid, :to => :descMetadata
        end
      end
      end
    end
  end
end