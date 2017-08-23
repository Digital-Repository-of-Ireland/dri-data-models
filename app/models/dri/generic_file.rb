# DRI namespace
module DRI
  # Implementation of DRI EAD generic files (digital assets) extending from AF Base
  # and associated to Digital Objects extending from DRI::Base
  # DRI::EncodedArchivalDescription, DRI::QualifiedDublinCore, DRI::Mods, DRI::Marc
  # DRI::Documentation
  class GenericFile < ActiveRecord::Base
    include ActiveFedora::Indexing
    include Hydra::Derivatives::ExtractMetadata

    include DRI::Noid
    include DRI::Export
    include DRI::Asset::MimeTypes
    include DRI::Asset::Characterization
    include DRI::Asset::Permissions::Readable
    include DRI::Asset::Derivatives
    include DRI::Asset::Versions
    
    include DRI::ModelSupport::LocalFile

    before_destroy :delete_files # callback delete files from S3 buckets if deleting the object

    # one-to-one AF association to associate DRI::Base
    belongs_to :digital_object, class_name: 'DRI::DigitalObject', polymorphic: true

    serialize :title
    serialize :creator

    def declared_attached_files
      { 'characterization' => characterization }
    end

    def add_depositor_metadata(current_user)
      depositor = current_user.to_s
    end

    # Return number of milliseconds for the duration of this asset file
    # @return [Integer] number of milliseconds
    def milliseconds
      characterization.milliseconds.blank? ? characterization.video_milliseconds : characterization.milliseconds
    end

    # Override from AF method
    def to_solr(solr_doc = {}, opts = {})
      solr_doc = super(solr_doc, opts)

      if digital_object
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name(ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, :symbol) => [digital_object.id])
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
      # Index the Fedora-generated SHA1 digest to create a linkage
      # between files on disk (in fcrepo.binary-store-path) and objects
      # in the repository.
      #solr_doc[ActiveFedora.index_field_mapper.solr_name('digest', :symbol)] = digest_from_content
      
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

    private

      def delete_files
        local_file_info = DRI::GenericFile.where('digital_object_id LIKE :f',
                                          f: id).order('version DESC').to_a
        local_file_info.each(&:destroy)
        FileUtils.remove_dir(Rails.root.join(Settings.dri.files).join(id), force: true)
      end
  end
end
