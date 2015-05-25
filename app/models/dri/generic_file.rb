module DRI
  class GenericFile < ActiveFedora::Base
    include Sufia::GenericFile
    include Sufia::ModelMethods
    include Sufia::Noid
    include Sufia::GenericFile::MimeTypes
    include Sufia::GenericFile::Export
    include Sufia::GenericFile::Characterization
    include Sufia::GenericFile::Audit
    include Sufia::GenericFile::Permissions
    include Sufia::GenericFile::WebForm
    include Sufia::GenericFile::Derivatives
    #include Sufia::GenericFile::Trophies
    include Sufia::GenericFile::Metadata
    include Sufia::GenericFile::Versions
    include Sufia::GenericFile::VirusCheck
    include Sufia::GenericFile::ReloadOnSave
    include Sufia::GenericFile::FullTextIndexing

    #after_initialize :redirect_content
    before_destroy :delete_files

    belongs_to :batch, :class_name => "DRI::Batch", property: :is_part_of
    # Declare a 'dri_properties' DS, of the following type
    has_metadata :name => "dri_properties", :type => DRI::Metadata::FileProperties

    # Declare the attributes of 'dri_properties' DS - 'checksum_md5...' - and that the DS is non-repeatable
    has_attributes :checksum_md5, datastream: :dri_properties, multiple: false
    has_attributes :checksum_sha256, datastream: :dri_properties, multiple: false
    has_attributes :checksum_rmd160, datastream: :dri_properties, multiple: false
    has_attributes :preservation_only, datastream: :dri_properties, multiple: false

    # DRI is not storing files in Fedora (which would be too slow to be of practical use),
    # instead a datastream will link to a URL in the DRI storage system.
    def update_file_reference(dsid, opts)
      if datastreams.has_key?(dsid)
        (send dsid).dsLocation = opts[:url]
        if opts.has_key?(:mimeType)
          (send dsid).mimeType = opts[:mimeType]
        end
        (send dsid).controlGroup = 'R'
        true
      else
        false
      end
    end

    def milliseconds
      characterization.milliseconds.blank? ? characterization.video_milliseconds : characterization.milliseconds
    end

    # Unstemmed, searchable, stored
    def noid_indexer
      @noid_indexer ||= Solrizer::Descriptor.new(:text, :indexed, :stored)
    end

    def to_solr(solr_doc={}, opts={})
      super(solr_doc, opts)
      solr_doc[Solrizer.solr_name('noid', noid_indexer)] = noid

      solr_doc.merge!(solr_name('file_size', :stored_sortable, type: :integer) => [file_size[0]]) unless file_size.empty?
      solr_doc.merge!(solr_name('width', :stored_sortable, type: :integer) => [width[0]]) unless width.empty?
      solr_doc.merge!(solr_name('height', :stored_sortable, type: :integer) => [height[0]]) unless height.empty?
      if (!width.empty? && !height.empty?)
        solr_doc.merge!(solr_name('area', :stored_sortable, type: :integer) => [width[0].to_i*height[0].to_i])
      end

      solr_doc.merge!(solr_name('duration', :stored_sortable, type: :integer) => [milliseconds[0]]) unless milliseconds.empty?
      solr_doc.merge!(solr_name('channels', :stored_sortable, type: :integer) => [channels[0]]) unless channels.empty?
      solr_doc.merge!(solr_name('sample_rate', :stored_sortable, type: :integer) => [sample_rate[0]]) unless sample_rate.empty?
      #solr_doc.merge!(solr_name('bit_depth', :stored_sortable, type: :integer) => bit_depth)

      file_type = []
      file_type.push "audio" if audio?
      file_type.push "video" if video?
      file_type.push "image" if image?
      file_type.push "text" if text?
      solr_doc.merge!(solr_name('file_type', :stored_searchable) => file_type)
      solr_doc.merge!(solr_name('file_type', :facetable) => file_type)

      solr_doc
    end

    private

    def delete_files
      local_file_info = LocalFile.where("fedora_id LIKE :f AND ds_id LIKE :d",
                                        { :f => self.id, :d => 'content' }).order("version DESC").to_a
      local_file_info.each { |file| file.destroy }
      FileUtils.remove_dir(Rails.root.join(Settings.dri.files).join(self.id), :force => true)

      storage = Storage::S3Interface.new
      storage.delete_bucket(Utils.split_id(self.id))
    end
  end
end
