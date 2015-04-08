module DRI
  module ModelSupport
    module EadSupport
      extend ActiveSupport::Concern
      
      def synchronize_children_to_metadata
        if self.new_record?
          return
        end
        if descMetadata.class == DRI::Metadata::EncodedArchivalDescription ||
           descMetadata.class == DRI::Metadata::EncodedArchivalDescriptionComponent

          metadata_child_index = 0

          prev_obj = nil
          child_obj = nil

          # FIXME See desc below
          # If the current object is an EAD root collection and the repo is empty then we do not call find
          # If called it will raise an exception since the collection_id and the is_first_sibling solr terms
          # are not stored in the index
          #if (is_root_collection?)
          #  child_obj = []
          #else
            # Find the first child (child not preceded by another child) of the current object
            # Changed way of retrieving children from Solr. Exact match query by collection_id needed
            solr_query = "collection_id_tesim:\"#{pid.to_s}\" AND is_first_sibling_tesim:1"
            # The query service returns back a set of Solr Documents, therefore need to be casted later on
            child_obj = ActiveFedora::SolrService.query(solr_query, :defType => "edismax")
            # Add type: :string to solr_name
            #child_obj = EncodedArchivalDescription.find(solr_name('collection_id', :stored_searchable, type: :string) => pid.to_s, solr_name('is_first_sibling', :stored_searchable) => "1")
            # Important! - added pid.to_s to the query above to ensure a Solr exact match query.
          #end

          if child_obj == []
            child_obj = nil
          elsif child_obj != nil
            # Line below if using EAD.find method for retrieving children
            #child_obj = child_obj[0] unless child_obj == nil
            # If using SolrService.query
            # Create an instance of Solr document from the retrieved first child
            doc = SolrDocument.new(child_obj[0])
            # Cast the solr document to its corresponding Fedora object
            child_obj = EncodedArchivalDescription.find(doc.id)
          end

          # Find the immediate children of this collection in the metadata
          metadata_children = []

          # Remove Ead namespaces
          fullMetadataNoNs = self.fullMetadata.ng_xml.clone
          fullMetadataNoNs.remove_namespaces!
          if descMetadata.class == DRI::Metadata::EncodedArchivalDescription
            #metadata_children = self.fullMetadata.ng_xml.xpath("/ead/archdesc/dsc/*")
            metadata_children = fullMetadataNoNs.xpath("/ead/archdesc/dsc/*")
          else
            #metadata_children = fullMetadataNoNs.remove_namespaces!.xpath("/*/dsc/*")
            # FIXME Original statement - this only works for components under dsc.
            #metadata_children = get_ead_children_components(self.fullMetadata.ng_xml)
            metadata_children = get_ead_children_components(fullMetadataNoNs)
          end

          if metadata_children.empty?
            # Find all the objects for which the ancestor is the current EAD object
            # Important! - added pid.to_s to the query below to ensure a Solr exact match query.
            # Changed way of retrieving children from Solr. Exact match query by ancestor_id needed
            solr_query = "ancestor_id_tesim:\"#{pid.to_s}\""

            # Line below uncommented if using EAD.find
            # EncodedArchivalDescription.find(solr_name('ancestor_id', :stored_searchable) => self.pid.to_s).each do |obj|
            # The query service returns back a set of Solr Documents, therefore need to be casted later on
            ActiveFedora::SolrService.query(solr_query, :defType => "edismax").each do |obj|
              # If using SolrService.query
              # Create an instance of Solr document
              doc = SolrDocument.new(obj)
              # Cast the solr document to its corresponding Fedora object
              obj = EncodedArchivalDescription.find(doc.id)
              obj.generic_files.each do |file_obj|
                file_obj.delete
              end
              obj.delete
            end
          end

          while metadata_child_index < metadata_children.length do
            #metadata_cc = metadata_children[metadata_child_index].xpath('did/unitid/@countrycode')[0].value
            #metadata_rc = metadata_children[metadata_child_index].xpath('did/unitid/@repositorycode')[0].value
            #metadata_id = metadata_children[metadata_child_index].xpath('did/unitid/@identifier')[0].value


            #if child_obj != nil &&
            #    child_obj.identifier.include?(metadata_id) &&
            #    child_obj.country_code == metadata_cc &&
            #    child_obj.repository_code == metadata_rc

            if is_ead_same_object?(child_obj, metadata_children[metadata_child_index])
              # Metadata identifiers match current child's identifiers
              # we can replace the child's metadata if the replacement metadata differs

              # fullMetadata automatically adds an XML header to the start and an extra "\n" at the end.
              # we have to undo these modifications in order to do the comparison
              #clean_fullMetadata = child_obj.fullMetadata.ng_xml.to_s[22..-1]

              cfullMetadataNoNs = child_obj.fullMetadata.ng_xml.clone
              cfullMetadataNoNs.remove_namespaces!
              #clean_fullMetadata = child_obj.fullMetadata.ng_xml.to_s[22..-1]
              clean_fullMetadata = cfullMetadataNoNs.to_s[22..-1]
              clean_fullMetadata = clean_fullMetadata[0..-2]

              # now we can do the comparison
              if (metadata_children[metadata_child_index].to_s != clean_fullMetadata)
                child_obj.update_metadata metadata_children[metadata_child_index].to_s
                child_obj.previous_sibling = prev_obj

                if child_obj.valid?
                  child_obj.save
                  # add to queue
                end

              end
              prev_obj = child_obj
              child_obj = prev_obj.next_sibling
              metadata_child_index += 1

            elsif child_obj != nil
              # TODO: DELETE child
              Rails.logger.info("Delete child needed")
            else
              # Create a new child
              new_child = EncodedArchivalDescription.new :component
              new_child.update_metadata metadata_children[metadata_child_index].to_xml
              new_child.previous_sibling = prev_obj
              new_child.governing_collection = self
              # Add depositor, status and rightsMetadata from parent
              new_child.depositor = self.depositor
              new_child.status = self.status
              new_child.datastreams['rightsMetadata'].content = self.rightsMetadata.content
              # ingest_files_from_metadata
              new_child.ingest_files_from_metadata = ingest_files_from_metadata
              # FIXME Need to call checksum method below but this method is implemented in dri_app
              # MetadataHelpers.checksum_metadata(new_child)
              #new_child.private_metadata="0"
              #new_child.master_file="1"

              # Don't add new node if it's invalid
              if new_child.valid?
                Rails.logger.info("EAD_SAVE: #{new_child.title} is valid!")
                new_child.save

                # add to queue
                prev_obj = new_child
              else
                # TODO Notify DRI App that there are invalid objects!!
                Rails.logger.error("ERR_EAD_SAVE: #{!new_child.title.empty? ? new_child.title : new_child.identifier}")
                new_child.errors.messages.each do |key, value|
                  Rails.logger.error("#{key}: #{value}")
                end
              end

              metadata_child_index += 1
            end
          end
        # check if child != nil and child matches metadata_marker
        #   check if difference in xml
        #     replace child xml
        #     child previous_sibling = prev_node
        #     save child
        #     prev_node = child
        #     queue up child
        #   child = child.next_sibling
        #   marker++
        # TODO For EAD Updates the case below is unimplemented
        # else if child != nil and check if child identifier is not in metadata
        #   child = child.next_sibling
        #   delete node and it's children
        # TODO For EAD Updates the case below is unimplemented
        # else if child != nil and check if metadata is in children
        #   prev_later_child = later_child.prev_sibling
        #   later_child.prev_sibling = prev_child
        #   prev_later_child.next_sibling = late_child.next_sibling
        #   don't sync prev_later_child
        #   prev_later_child.save
        #   replace later_child xml
        #   late_child.next_sibling = nil
        #   save later_child
        #   marker++
        # else
        #   if not, create temp_child using metadata
        #   temp_child.prev_sibling = prev_node
        #   copy permissions
        #   save temp_child
        #   queue up temp_child
        #   prev_node = temp_child
        #   marker++

        # Delete any remaining children
          while child_obj != nil do
            to_delete = child_obj
            child_obj = child_obj.next_sibling

            solr_query = "ancestor_id_tesim:\"#{to_delete.pid.to_s}\""

            # Important! - added pid.to_s to the query below to ensure a Solr exact match query.
            # Line below uncommented if using EAD.find
            #EncodedArchivalDescription.find(solr_name('ancestor_id', :stored_searchable) => to_delete.pid.to_s).each do |obj|

            # The query service returns back a set of Solr Documents, therefore need to be casted later on
            ActiveFedora::SolrService.query(solr_query, :defType => "edismax").each do |obj|
              # If using SolrService.query
              # Create an instance of Solr document
              doc = SolrDocument.new(obj)
              # Cast the solr document to its corresponding Fedora object
              obj = EncodedArchivalDescription.find(doc.id)
              obj.generic_files.each do |file_obj|
                file_obj.delete
              end
              obj.delete
            end
            to_delete.delete
          end
        end
      end # synchronize_children_to_metadata

      private

      # Checks that the metadata identifiers match the identifiers of the current EAD component child
      # being analysed
      # @param child_obj the current EAD stored child
      # @param elem the new EAD child from metadata
      # @return[boolean] true if the identifiers match
      def is_ead_same_object?(child_obj, elem)
        repository_code_attr = nil
        country_code_attr = nil

        # Get the text value for unitid
        metadata_id = !elem.xpath('did/unitid')[0].text.nil? ? elem.xpath('did/unitid')[0].text : ""

        # Get the value of unitid/@repositorycode
        if elem.xpath('did/unitid/@repositorycode')[0] != nil
          repository_code_attr = elem.xpath('did/unitid/@repositorycode')[0].value
        end
        # Get the value of unitid/@countrycode
        if elem.xpath('did/unitid/@countrycode')[0] != nil
          country_code_attr = elem.xpath('did/unitid/@countrycode')[0].value
        end

        # To check that the metadata ids match the current child's ids
        # we need to look first at the value of unitid/eadid AND
        # then compare against the following attributes of unitid: repositorycode/mainagencycode and countrycode
        if (child_obj != nil &&
            child_obj.identifier.include?(metadata_id) &&
            child_obj.repository_code == repository_code_attr &&
            child_obj.country_code == country_code_attr)
          return true
        else
          return false
        end
      end # is_ead_same_element?

      def is_child_id_in_metadata(child_obj, md_elem)
        # TODO Implement method for checking whether an existing child identifier is present in new metadata when updating collections
      end # is_child_id_in_metadata

      # Returns an array of children ead components
      # @param Nokogiri::XML
      # @return Nokogiri::XML::NodeSet (Array of EAD Components)
      def get_ead_children_components(metadata)
        # Components in EAD can either be children of dsc; or children of c
        # 1. dsc/c
        return metadata.xpath("/*/dsc/*") unless metadata.xpath("/*/dsc/*").empty?
        # 2. c/c and 3. c01/c02/...
        # For Xpath 2.0
        # return metadata.xpath("/*/*[matches(local-name(), 'c[01-12]')]") unless metadata.xpath("/*/*[matches(local-name(),'c[01-12]')]").empty?
        # For Xpath 1.0
        return metadata.xpath("/*/*[starts-with(local-name(), 'c')]")
      end
    end # module
  end # module
end # module
