module DRI
  class GenericFile < ActiveFedora::Base
    include Sufia::ModelMethods
    include Sufia::Noid
    include Sufia::GenericFile::MimeTypes
    include Sufia::GenericFile::Export
    include Sufia::GenericFile::Characterization
    include Sufia::GenericFile::Permissions
    include Sufia::GenericFile::Derivatives
    include Sufia::GenericFile::Featured
    include Sufia::GenericFile::Metadata
    include Sufia::GenericFile::Content
    include Sufia::GenericFile::Versions
    include Sufia::GenericFile::VirusCheck
    include Sufia::GenericFile::FullTextIndexing
    include Sufia::GenericFile::ProxyDeposit
    include Hydra::Collections::Collectible
    include Sufia::GenericFile::Batches
    include Sufia::GenericFile::Indexing

    before_destroy :delete_files

    belongs_to :batch, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'DRI::Batch'

    # Declare a 'dri_properties' DS, of the following type
    contains 'dri_properties', class_name: 'DRI::Metadata::FileProperties'

    # Declare the attributes of 'dri_properties' DS - 'checksum_md5...' - and that the DS is non-repeatable
    property :checksum_md5, delegate_to: 'dri_properties', multiple: false
    property :checksum_sha256, delegate_to: 'dri_properties', multiple: false
    property :checksum_rmd160, delegate_to: 'dri_properties', multiple: false
    property :preservation_only, delegate_to: 'dri_properties', multiple: false

    def initialize(args = {})
      # FIXME: Bug 1320
      args[:id] = self.assign_id unless args[:id].present?

      super(args)
    end

    # DRI is not storing files in Fedora (which would be too slow to be of practical use),
    # instead a datastream will link to a URL in the DRI storage system.
    def update_file_reference(dsid, opts)
      options = {}

      options[:mime_type] = opts[:mimeType] if opts.key?(:mimeType)

      options[:path] = dsid
      attach_file(opts[:url], dsid, options)

      true
    end

    def milliseconds
      characterization.milliseconds.blank? ? characterization.video_milliseconds : characterization.milliseconds
    end

    def to_solr(solr_doc = {}, opts = {})
      solr_doc = super(solr_doc, opts)

      solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('file_size', :stored_sortable, type: :integer) => [file_size[0]]) unless file_size.empty?
      solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('width', :stored_sortable, type: :integer) => [width[0]]) unless width.empty?
      solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('height', :stored_sortable, type: :integer) => [height[0]]) unless height.empty?
      unless width.empty? || height.empty?
        solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('area', :stored_sortable, type: :integer) => [width[0].to_i * height[0].to_i])
      end

      solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('duration', :stored_sortable, type: :integer) => [milliseconds[0]]) unless milliseconds.empty?
      solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('channels', :stored_sortable, type: :integer) => [channels[0]]) unless channels.empty?
      solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('sample_rate', :stored_sortable, type: :integer) => [sample_rate[0]]) unless sample_rate.empty?

      file_type = []
      file_type.push('audio') if audio?
      file_type.push('video') if video?
      file_type.push('image') if image?
      file_type.push('text') if text?
      solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('file_type', :stored_searchable) => file_type) unless file_type.empty?
      solr_doc.merge!(ActiveFedora::SolrQueryBuilder.solr_name('file_type', :facetable) => file_type) unless file_type.empty?

      solr_doc
    end

    ## Extract the metadata from the content datastream and record it in the characterization datastream
    ## Issue
    ## Override to fix issue with sample_rate or height or width md terms from FITS being generated as float
    ## as opposed to integer strings. this was causing Solr errors when indexing as the Solr fields are integers
    def characterize
      metadata = content.extract_metadata
      characterization.ng_xml = round_float_values(metadata) if metadata.present?
      append_metadata
      self.filename = [content.original_name]
      save
    end

    private

    def delete_files
      local_file_info = LocalFile.where('fedora_id LIKE :f AND ds_id LIKE :d',
                                        f: id, d: 'content').order('version DESC').to_a
      local_file_info.each(&:destroy)
      FileUtils.remove_dir(Rails.root.join(Settings.dri.files).join(id), force: true)
    end

    def round_float_values(md_xml)
      doc = Nokogiri::XML::Document.parse(md_xml)
      doc.search('//fits:sampleRate | //fits:height | //fits:width', 'fits' => 'http://hul.harvard.edu/ois/xml/ns/fits/fits_output').each do |node|
        node.content = (node.text.to_f.round).to_s
      end

      doc.to_xml
    end
  end
end
