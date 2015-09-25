module DRI
  module ModelSupport
    module EadSupport
      extend ActiveSupport::Concern

      included do
        around_save :ingest_files_if_changed

        attr_accessor :trigger_ingest
        attr_accessor :trigger_update

        # Issue 1195 - Trigger ingest, additional flag to avoid ead updates when loading fedora objects
        # load_attributes changes the descMetadata datastream to load the right metadata class
        def trigger_ingest
          @trigger_ingest || false
        end

        # Individual object metadata update flag
        def trigger_update
          @trigger_update || false
        end
      end

      # Process a component's children and create associated objects in Fedora
      def synchronize_children_to_metadata
        if self.new_record?
          return
        end

        metadata_child_index = 0
        prev_obj = nil
        metadata_children = []

        # Remove Ead namespaces
        full_metadata_nons = self.fullMetadata.ng_xml.clone
        full_metadata_nons.remove_namespaces!

        # Find the immediate children of this collection in the metadata
        case self.descMetadata.class.to_s
        when 'DRI::Metadata::EncodedArchivalDescription'
          metadata_children = full_metadata_nons.xpath('/ead/archdesc/dsc/*')
        when 'DRI::Metadata::EncodedArchivalDescriptionComponent'
          metadata_children = get_ead_children_components(full_metadata_nons)
        else
          metadata_children = []
        end

        while metadata_child_index < metadata_children.length do
          # Create a new child
          new_child = DRI::EncodedArchivalDescription.new(:component)
          new_child.update_metadata metadata_children[metadata_child_index].to_xml
          new_child.previous_sibling = prev_obj unless prev_obj.nil?
          new_child.governing_collection = self
          # Add depositor, status and permissions from parent
          new_child.depositor = self.depositor
          new_child.status = self.status
          # Copy permissions from parent
          new_child.read_groups_string = self.read_groups_string
          new_child.edit_groups_string = self.edit_groups_string
          new_child.manager_groups_string = self.manager_groups_string
          new_child.manager_users_string = self.manager_users_string
          # ingest_files_from_metadata
          new_child.ingest_files_from_metadata = self.ingest_files_from_metadata
          checksum_metadata(new_child)
          duplicates = object_duplicates?(new_child)
          #duplicates = false
          # Don't add new node if it's invalid
          if new_child.valid? && !duplicates
            Rails.logger.info("EAD_SAVE: #{new_child.title} is valid!")
            new_child.save
            begin
              create_reader_group(new_child.id) if new_child.is_collection?
            rescue
              Rails.logger.error("synchronize_children_to_metadata: SQL exception in create_reader_group for object: #{new_child.id} ")
            end
            retrieve_linked_data(new_child)
            # add to queue
            prev_obj = new_child
          elsif duplicates
            Rails.logger.error("ERR_EAD_SAVE: #{new_child.identifier} is duplicated!!")
          else
            Rails.logger.error("ERR_EAD_SAVE: #{!new_child.title.empty? ? new_child.title : new_child.identifier}")
            new_child.errors.messages.each do |key, value|
              Rails.logger.error("#{key}: #{value}")
            end
          end

          metadata_child_index += 1
        end
      end # synchronize_children_to_metadata

      # Create associated generic file from a given URL
      def process_ingest_of_file_urls
        case descMetadata
        when DRI::Metadata::EncodedArchivalDescription
        when DRI::Metadata::EncodedArchivalDescriptionComponent
          self.dao_href_proxy.each do |url|
            if !url.blank?
              add_file_from_url url.strip
            end
          end
        else # Do nothing
        end
      end # process_ingest_of_file_urls

      # Ingest a file (generic_file) from a given URL
      def add_file_from_url file_url
        file_name = File.basename(URI(file_url).path)
        begin

          # We have a copy of the remote file for processing
          temp_file = Tempfile.new(['tmp', File.extname(file_url)])
          temp_file.binmode
          open(file_url) { |data| temp_file.write data.read}
          temp_file.close

          add_file temp_file, "content", file_name
          true
        rescue Exception => e
          logger.error "Error loading url: #{file_url} PID: #{self.id}\n"
          logger.error e.backtrace.join("\n")
          false
        ensure
          # Explicitly close the temp file
          temp_file.close unless temp_file.nil?
          temp_file.unlink unless temp_file.nil?
        end
      end # add_file_from_url

      # Searchs for the node's children ead:components (c | c01..12 XML nodes)
      # @param [Nokogiri::XML::Document] node the document to search
      # @return [Nokogiri::XML::NodeSet] the children ead:components for the given node
      def self.get_ead_metadata_components(node)
        if node.collect_namespaces['xmlns:ead'] == 'urn:isbn:1-931666-22-9'
          ns_dcl = {'xmlns:ead' => 'urn:isbn:1-931666-22-9'}
          # Nodes for EAD root collection (as path differs)
          return node.xpath('/ead:ead/ead:archdesc/ead:dsc/*', ns_dcl) unless node.xpath('/*/ead:archdesc', ns_dcl).empty?
          # Nodes for components grouped under dsc
          return node.xpath('/*/ead:dsc/*', ns_dcl) unless node.xpath('/*/ead:dsc/*', ns_dcl).empty?

          # Nodes for components directly nested under the parent component: c or c[01-12]
          node.xpath('/*/*[starts-with(local-name(), "c") and string-length(local-name()) <= 3]', ns_dcl)
        else
          # Nodes for EAD root collection (as path differs)
          return node.xpath('/ead/archdesc/dsc/*') unless node.xpath('/*/archdesc').empty?
          # Nodes for components grouped under dsc
          return node.xpath('/*/dsc/*') unless node.xpath('/*/dsc/*').empty?

          # Nodes for components directly nested under the parent component: c or c[01-12]
          node.xpath('/*/*[starts-with(local-name(), "c") and string-length(local-name()) <= 3]')
        end
      end

      private

      # Returns an array of children EAD components
      # @param metadata [Nokogiri::XML] EAD component XML metadata
      # @return [Array<Nokogiri::XML::NodeSet>] Array of children EAD components
      def get_ead_children_components(metadata)
        # Components in EAD can either be children of dsc; or children of c
        # 1. dsc/c
        return metadata.xpath('/*/dsc/*') unless metadata.xpath('/*/dsc/*').empty?
        # 2. c/c and 3. c01/c02/...
        # For Xpath 2.0
        # return metadata.xpath("/*/*[matches(local-name(), 'c[01-12]')]") unless metadata.xpath("/*/*[matches(local-name(),'c[01-12]')]").empty?
        # For Xpath 1.0
        metadata.xpath('/*/*[starts-with(local-name(), "c") and string-length(local-name()) <= 3]')
      end

      # Checks whether the passed object is a duplicate
      # @param object [DRI::Batch] the object to check
      # @return [Boolean] true if object is a duplicate; false otherwise
      def object_duplicates?(object)
        result = false

        if object.governing_collection.present?
          collection_id = object.governing_collection.id
          solr_query = "#{ActiveFedora::SolrQueryBuilder.solr_name('metadata_md5', :stored_searchable, type: :string)}:\"#{object.metadata_md5}\" AND #{ActiveFedora::SolrQueryBuilder.solr_name('isGovernedBy', :stored_searchable, type: :symbol)}:\"#{collection_id}\""
          documents = ActiveFedora::SolrService.query(solr_query, :defType => 'edismax', :rows => '10', :fl => 'id').delete_if { |obj| obj["id"] == object.id }
          result = true unless documents.empty?
        end

        result
      end

      # Create deafult reader group permissions for the object and save
      # @param object [DRI::Batch] the object for which to add a default reader group
      def create_reader_group(id)
        grp = UserGroup::Group.new(:name => id, :description => "Default Reader group for collection #{id}")
        grp.reader_group = true
        grp.save
      end

      # Adds linked data records for logaimn links present in the metadata (geographical_coverage)
      # @param obj [DRI::Batch] the object to check
      def retrieve_linked_data(obj)
        if AuthoritiesConfig
          begin
            Sufia.queue.push(LinkedDataJob.new(obj.id)) unless obj.geographical_coverage.blank?
          rescue Exception => e
            Rails.logger.error "Unable to submit linked data job: #{e.message}"
          end
        end
      end

      # Generates metadata checksum for the object
      # @param object [DRI::Batch] the digital object
      def checksum_metadata(object)
        if object.attached_files.has_key?(:descMetadata)
          xml = object.attached_files[:descMetadata].content
          object.metadata_md5 = Checksum.md5_string(xml)
        end
      end

      # Triggers the creation of generic files for EAD components if specified in metadata
      def ingest_files_if_changed
        content_changed = false

        if self.ingest_files_from_metadata == 'true' && self.trigger_ingest
          content_changed = self.descMetadata.changed?
        end

        # Does the actual collection/file save
        yield

        # Do not process files if object is a collection (DRI Collections do not have assets)
        unless is_collection?
          if content_changed && self.generic_files.empty? &&
              !self.dao_href_proxy.empty? && !new_record?
            Sufia.queue.push(IngestFilesFromMetadataJob.new(self.id))
          end
        end
      end # ingest_files_if_changed
    end # module
  end # module
end # module
