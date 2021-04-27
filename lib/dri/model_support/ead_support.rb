# frozen_string_literal: true
# DRI namespace
module DRI
  # ModelSupport namespace
  module ModelSupport
    # Includes methods to handle EAD metadata, children component creation/management
    module EadSupport
      extend ActiveSupport::Concern

      included do
        around_save :ingest_files_if_changed # callback for generating EAD Generic Files from ead:dao links

        attr_accessor :trigger_ingest
        attr_accessor :trigger_update

        # Issue 1195 - Trigger ingest, additional flag to avoid ead updates when loading objects
        # load_attributes changes the descMetadata datastream to load the right metadata class
        def trigger_ingest
          @trigger_ingest || false
        end

        # Individual object metadata update flag
        def trigger_update
          @trigger_update || false
        end
      end

      # Process a component's children and create associated objects
      def synchronize_children_to_metadata
        return if self.new_record?

        metadata_child_index = 0
        prev_obj = nil
        metadata_children = []

        # Remove Ead namespaces
        full_metadata_nons = fullMetadata.ng_xml.clone
        full_metadata_nons.remove_namespaces!

        # Find the immediate children of this collection in the metadata
        case descMetadata.class.to_s
        when 'DRI::Metadata::EncodedArchivalDescription'
          metadata_children = full_metadata_nons.xpath('/ead/archdesc/dsc/*')
        when 'DRI::Metadata::EncodedArchivalDescriptionComponent'
          metadata_children = ead_children_components(full_metadata_nons)
        else
          metadata_children = []
        end

        while metadata_child_index < metadata_children.length
          # Create a new child
          new_child = DRI::EadComponent.new
          new_child.update_metadata metadata_children[metadata_child_index].to_xml
          new_child.previous_sibling = prev_obj unless prev_obj.nil?
          new_child.governing_collection = self
          # Add depositor and status from parent
          new_child.depositor = depositor
          new_child.status = status

          # ingest_files_from_metadata
          new_child.ingest_files_from_metadata = ingest_files_from_metadata
          DRI::Utils.checksum_metadata(new_child)
          duplicates = object_duplicates?(new_child)
          # duplicates = false
          # Don't add new node if it's invalid
          if new_child.valid? && !duplicates
            Rails.logger.info("EAD_SAVE: #{new_child.title} is valid!")
            new_child.save
            # Do the preservation actions
            preserve(new_child)
            begin
              DRI::Utils.create_reader_group(new_child.alternate_id) if new_child.collection?
            rescue
              Rails.logger.error("synchronize_children_to_metadata: SQL exception in create_reader_group for object: #{new_child.id} ")
            end
            DRI::Utils.retrieve_linked_data(new_child)
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

      def preserve(new_child)
        preservation = ::Preservation::Preservator.new(new_child)
        preservation.preserve(['descMetadata'])
      end

      # Create associated generic file from a given URL
      def process_ingest_of_file_urls
        return unless descMetadata.is_a?(DRI::Metadata::EncodedArchivalDescriptionComponent)

        dao_href_proxy.each do |url|
          add_file_from_url(url.strip) if url.present?
        end
      end # process_ingest_of_file_urls

      # Ingest a file (generic_file) from a given URL
      # @param file_url [String] the URL of the ead:dao asset to add
      # @return [Boolean] true if successful; false otherwise
      def add_file_from_url(file_url)
        file_name = File.basename(URI(file_url).path)
        begin
          # We have a copy of the remote file for processing
          temp_file = Tempfile.new(['tmp', File.extname(file_url)])
          temp_file.binmode
          open(file_url) { |data| temp_file.write data.read }
          temp_file.close

          added = add_file_to_object(temp_file, file_name)
          return added unless added

          true
        rescue => e
          logger.error "Error loading url: #{file_url} PID: #{alternate_id}\n"
          logger.error e.backtrace.join("\n")

          false
        ensure
          # Explicitly close the temp file
          temp_file.close unless temp_file.nil?
          temp_file.unlink unless temp_file.nil?
        end
      end # add_file_from_url

      def add_file_to_object(temp_file, file_name); end

      # Searchs for the node's children ead:components (c | c01..12 XML nodes)
      # @param [Nokogiri::XML::Document] node the document to search
      # @return [Nokogiri::XML::NodeSet] the children ead:components for the given node
      def self.ead_metadata_components(node)
        if node.collect_namespaces['xmlns:ead'] == 'urn:isbn:1-931666-22-9'
          ns_dcl = { 'xmlns:ead' => 'urn:isbn:1-931666-22-9' }
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

      # Should only be set in a new class
      def desc_metadata_class=(desc_metadata_class)
        @desc_metadata_class = desc_metadata_class if self.new?
      end

      private

      def metadata_class_from_xml(xml_text)
        ead_components = %w[c c01 c02 c03 c04 c05 c06 c07 c08 c09 c10 c11 c12]

        xml = if xml_text.is_a? Nokogiri::XML::Document
                xml_text
              else
                Nokogiri::XML xml_text
              end

        root_name = xml.root.name
        result = if (xml.internal_subset.present? && xml.internal_subset.name == 'ead') || root_name == 'ead'
                   'DRI::Metadata::EncodedArchivalDescription'
                 elsif ead_components.include? root_name
                   'DRI::Metadata::EncodedArchivalDescriptionComponent'
                 end

        result
      end # metadata_class_from_xml

      # Returns an array of children EAD components
      # @param metadata [Nokogiri::XML] EAD component XML metadata
      # @return [Array<Nokogiri::XML::NodeSet>] Array of children EAD components
      def ead_children_components(metadata)
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
      # @param object [DRI::DigitalObject] the object to check
      # @return [Boolean] true if object is a duplicate; false otherwise
      def object_duplicates?(object)
        return false if object.governing_collection.blank?

        duplicates = DRI::DigitalObject.where.not(id: object.id).where(metadata_checksum: object.metadata_checksum, governing_collection_id: object.governing_collection_id)
        !duplicates.empty?
      end

      # Triggers the creation of generic files
      # for EAD components if specified in metadata
      def ingest_files_if_changed
        content_changed = false

        if ingest_files_from_metadata == 'true' && trigger_ingest
          content_changed = descMetadata.changed?
        end

        # Does the actual collection/file save
        yield

        # Do not process files if object is a collection (DRI Collections do not have assets)
        return if collection?

        if content_changed && generic_files.empty? &&
           !dao_href_proxy.empty? && !new_record?
          DRI.queue.push(IngestFilesFromMetadataJob.new(alternate_id))
        end
      end # ingest_files_if_changed
    end # module
  end # module
end # module
