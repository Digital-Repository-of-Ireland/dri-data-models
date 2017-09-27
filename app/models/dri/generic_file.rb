# DRI namespace
module DRI
  # Implementation of DRI generic files (digital assets) extending from AR Base
  # and associated to Digital Objects extending from DRI::DigitalObject
  # DRI::EncodedArchivalDescription, DRI::QualifiedDublinCore, DRI::Mods, DRI::Marc
  # DRI::Documentation
  class GenericFile < ActiveRecord::Base
    include ActiveFedora::Indexing
    include Hydra::Derivatives::ExtractMetadata

    include DRI::Permissions
    include DRI::ModelSupport::Permissions
    include Hydra::WithDepositor
    
    include DRI::Noid
    include DRI::Export
    include DRI::Asset::MimeTypes
    include DRI::Asset::Characterization
    include DRI::Asset::Permissions::Readable
    include DRI::Asset::Derivatives
    include DRI::Asset::Versions
    
    include DRI::ModelSupport::LocalFile

    has_one :alternate_identifier, class_name: 'DRI::Identifier', as: :identifiable, autosave: true

    # one-to-one AF association to associate DRI::DigitalObject
    belongs_to :digital_object, class_name: 'DRI::DigitalObject', polymorphic: true

    serialize :title
    serialize :creator

    def self.find_by_noid(pid)
      joins(:alternate_identifier).where(identifiers: { alternate_id: pid }).take
    end

    def self.find_by_noid!(pid)
      object = find_by_noid(pid)
      raise ActiveRecord::RecordNotFound.new("Couldn't find DRI::GenericFile with 'noid'=#{pid}") unless object

      object
    end

    def self.find_or_create(pid)
      DRI::GenericFile.find_by_noid!(pid)
    rescue ActiveRecord::RecordNotFound
      DRI::GenericFile.create(noid: pid)
    end

    def declared_attached_files
      { 'characterization' => characterization }
    end

    def attached_files
      declared_attached_files
    end

    def create_date
      return nil unless created_at
      DateTime.parse(created_at.to_s).utc
    end

    def modified_date
      return nil unless updated_at
      DateTime.parse(updated_at.to_s).utc
    end

    def noid
      alternate_identifier.alternate_id
    end

    def noid=(identifier)
      alternate_identifier.alternate_id=identifier
    end

    def alternate_identifier
      super || build_alternate_identifier
    end

    # Asserts the model class
    def has_model
      [self.class.to_s]
    end

    # Return number of milliseconds for the duration of this asset file
    # @return [Integer] number of milliseconds
    def milliseconds
      characterization.milliseconds.blank? ? characterization.video_milliseconds : characterization.milliseconds
    end

    # Override from AF method
    def to_solr(solr_doc = {}, opts = {})
      solr_doc = indexing_service.generate_solr_document
      Solrizer.set_field(solr_doc, 'active_fedora_model', self.class.to_s, :stored_sortable)
      solr_doc[:id] = noid

      if digital_object
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name(ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf.fragment, :symbol) => [digital_object.noid])
      end

      solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('file_size', :stored_sortable, type: :integer) => [file_size[0]]) unless file_size.empty?
      solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('width', :stored_sortable, type: :integer) => [width[0].to_i]) unless width.empty?
      solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('height', :stored_sortable, type: :integer) => [height[0].to_i]) unless height.empty?
      unless width.empty? || height.empty?
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('area', :stored_sortable, type: :integer) => [width[0].to_i * height[0].to_i])
      end

      solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('duration', :stored_sortable, type: :integer) => [milliseconds[0]]) unless milliseconds.empty?
      solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('channels', :stored_sortable, type: :integer) => [channels[0]]) unless channels.empty?
      solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('sample_rate', :stored_sortable, type: :integer) => [sample_rate[0].to_i]) unless sample_rate.empty?

      file_type = []
      file_type.push('audio') if audio?
      file_type.push('video') if video?
      file_type.push('image') if image?
      file_type.push('text') if text?
      solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('file_type', :stored_searchable) => file_type) unless file_type.empty?
      solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('file_type', :facetable) => file_type) unless file_type.empty?

      solr_doc[ActiveFedora.index_field_mapper.solr_name('label')] = label
      solr_doc[ActiveFedora.index_field_mapper.solr_name('file_format')] = file_format
      solr_doc[ActiveFedora.index_field_mapper.solr_name('file_format', :facetable)] = file_format
      #solr_doc['all_text_timv'] = full_text.content
     
      solr_doc
    end

    def related_files
      return [] unless digital_object
      digital_object.generic_files.reject { |sibling| sibling.id == id }
    end

    # Is this file in the middle of being processed by an object?
    def processing?
      try(:digital_object).try(:status) == ['processing'.freeze]
    end

  end
end
