# DRI namespace
module DRI
  # Implementation of DRI EAD generic files (digital assets) extending from AF Base
  # and associated to Digital Objects extending from DRI::Batch:
  # DRI::EncodedArchivalDescription, DRI::QualifiedDublinCore, DRI::Mods, DRI::Marc
  # DRI::Documentation
  class GenericFile < ActiveFedora::Base
    #include Hydra::AccessControls::Permissions
    include DRI::ModelSupport::Permissions
    include Hydra::AccessControls::Visibility
    include Hydra::WithDepositor

    include DRI::Noid
    include DRI::Export
    include DRI::Asset::MimeTypes
    include DRI::Asset::Characterization
    include DRI::Asset::Permissions::Readable
    include DRI::Asset::Derivatives
    include DRI::Asset::Versions

    include DRI::Derivatives::ExtractMetadata

    before_destroy :delete_files # callback delete files from S3 buckets if deleting the object

    # one-to-one AF association to associate DRI::Batch
    belongs_to :batch,
               predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf,
               class_name: 'DRI::Batch'

    # Declare a 'dri_properties' DS, of the following type
    has_subresource 'dri_properties', class_name: 'DRI::Metadata::FileProperties'
    has_subresource 'content', class_name: 'FileContentDatastream'
    has_subresource 'full_text'

    property :title, predicate: ::RDF::Vocab::DC.title do |index|
      index.as :stored_searchable, :facetable
    end
    property :label, predicate: ActiveFedora::RDF::Fcrepo::Model.downloadFilename, multiple: false
    property :depositor, predicate: ::RDF::URI.new("http://id.loc.gov/vocabulary/relators/dpt"), multiple: false do |index|
      index.as :symbol, :stored_searchable
    end
    property :creator, predicate: ::RDF::Vocab::DC.creator do |index|
      index.as :stored_searchable, :facetable
    end

    # Declare the attributes of 'dri_properties' DS - 'checksum_md5...'
    # the DS is non-repeatable
    delegate :checksum_md5,:checksum_md5=, to: 'dri_properties'
    delegate :checksum_sha256,:checksum_sha256=, to: 'dri_properties'
    delegate :checksum_rmd160,:checksum_rmd160=, to: 'dri_properties'
    delegate :preservation_only,:preservation_only=, to: 'dri_properties'

    # DRI is not storing files in Fedora (which would be too slow to be of practical use),
    # instead a datastream will link to a URL in the DRI storage system.
    #
    # @param dsid [String] the datastream's identifier
    # @param opts [Hash] hash of additional options
    # @return [Boolean] true if operation successful; false otherwise
    def update_file_reference(dsid, opts)
      options = {}

      options[:mime_type] = opts[:mimeType] if opts.key?(:mimeType)

      options[:path] = dsid
      attach_file(opts[:url], dsid, options)

      true
    end

    # Return number of milliseconds for the duration of this asset file
    # @return [Integer] number of milliseconds
    def milliseconds
      characterization.milliseconds.blank? ? characterization.video_milliseconds : characterization.milliseconds
    end

    # Override from AF method
    def to_solr(solr_doc = {}, opts = {})
      solr_doc = super(solr_doc, opts)

      Solrizer.set_field(solr_doc, 'active_fedora_model', self.class.to_s, :stored_sortable)

      solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('file_size', :stored_sortable, type: :integer) => [file_size[0]]) unless file_size.empty?
      solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('width', :stored_sortable, type: :integer) => [width[0].to_i]) unless width.empty?
      solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('height', :stored_sortable, type: :integer) => [height[0].to_i]) unless height.empty?
      unless width.empty? || height.empty?
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('area', :stored_sortable, type: :integer) => [width[0].to_i * height[0].to_i])
      end

      solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('duration', :stored_sortable, type: :integer) => [milliseconds[0]]) unless milliseconds.empty?
      solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('channels', :stored_sortable, type: :integer) => [channels[0]]) unless channels.empty?
      solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('sample_rate', :stored_sortable, type: :integer) => [sample_rate[0].to_i]) unless sample_rate.empty?

      solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('mime_type', :stored_searchable) => mime_type) unless mime_type.empty?

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
      solr_doc['all_text_timv'] = full_text.content

      solr_doc
    end

    def related_files
      return [] unless batch
      batch.generic_files.reject { |sibling| sibling.id == id }
    end

    # Is this file in the middle of being processed by a batch?
    def processing?
      try(:batch).try(:status) == ['processing'.freeze]
    end

    private

    def delete_files
      local_file_info = LocalFile.where('fedora_id LIKE :f AND ds_id LIKE :d',
                                        f: id, d: 'content').order('version DESC').to_a
      local_file_info.each(&:destroy)
      FileUtils.remove_dir(Rails.root.join(Settings.dri.files).join(id), force: true)
    end
  end
end
