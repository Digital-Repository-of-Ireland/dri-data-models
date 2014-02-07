module DRI
  module ModelSupport
  	module InterchangeableMetadata
      extend ActiveSupport::Concern
    
      included do
        attr_accessor :desc_metadata_class

        has_metadata :name => "descMetadata", :type => ActiveFedora::OmDatastream
        has_metadata :name => "fullMetadata", :type => ActiveFedora::OmDatastream

        after_initialize :load_attributes
        after_save :reset_metadata_check
        around_save :synchronize_if_changed

        has_attributes :title, datastream: :descMetadata, multiple: true
        has_attributes :description, datastream: :descMetadata, multiple: true
        has_attributes :language, datastream: :descMetadata, multiple: true
        has_attributes :creator, datastream: :descMetadata, multiple: true
        has_attributes :contributor, datastream: :descMetadata, multiple: true
        has_attributes :publisher, datastream: :descMetadata, multiple: true
        has_attributes :date, datastream: :descMetadata, multiple: true
        has_attributes :published_date, datastream: :descMetadata, multiple: true
        has_attributes :creation_date, datastream: :descMetadata, multiple: true
        has_attributes :relation, datastream: :descMetadata, multiple: true
        has_attributes :subject, datastream: :descMetadata, multiple: true
        has_attributes :source, datastream: :descMetadata, multiple: true
        has_attributes :geographical_coverage, datastream: :descMetadata, multiple: true
        has_attributes :temporal_coverage, datastream: :descMetadata, multiple: true
        has_attributes :rights, datastream: :descMetadata, multiple: true
        has_attributes :type, datastream: :descMetadata, multiple: true
        has_attributes :format, datastream: :descMetadata, multiple: true
        has_attributes :coverage, datastream: :descMetadata, multiple: true
        has_attributes :identifier, datastream: :descMetadata, multiple: true
        has_attributes :geocode_point, datastream: :descMetadata, multiple: true
        has_attributes :geocode_box, datastream: :descMetadata, multiple: true
        has_attributes  *(DRI::Vocabulary::marcRelators.map { |s| s.prepend("role_").to_sym}), datastream: :descMetadata,
                                    multiple: true

        has_attributes :abstract, datastream: :descMetadata, multiple: false
        has_attributes :bioghist, datastream: :descMetadata, multiple: false
        has_attributes :scope_content, datastream: :descMetadata, multiple: false
        has_attributes :ead_level, datastream: :descMetadata, multiple: false
        has_attributes :name_coverage, datastream: :descMetadata, multiple: true
        has_attributes :physdesc, datastream: :descMetadata, multiple: true
        has_attributes :dao, datastream: :descMetadata, multiple: true
        has_attributes :dao_href, datastream: :descMetadata, multiple: true
        has_attributes :unitid, datastream: :descMetadata, multiple: false
        has_attributes :repository_code, datastream: :descMetadata, multiple: false
        has_attributes :country_code, datastream: :descMetadata, multiple: false

        validate :custom_validations
      end

      def roles= roles
        if descMetadata.class == DRI::Metadata::QualifiedDublinCore
          descMetadata.roles = roles
        end
      end

      def has_metadata_class_changed?
        if (@metadata_class != descMetadata.class)
          true
        else
          false
        end
      end

      # Should only be set in a new class
      def desc_metadata_class= desc_metadata_class
        if self.new?
          @desc_metadata_class = desc_metadata_class
        end
      end

      # Use this in preference over the setting xml directly in the OmDatastreams
      def update_metadata xml_text
        if (xml_text.is_a? File)
          xml_text = xml_text.read
        end

        curr_metadata = descMetadata.class.to_s
        replacing_metadata = get_metadata_class_from_xml xml_text

        if curr_metadata == replacing_metadata
          if replacing_metadata == "DRI::Metadata::EncodedArchivalDescription" ||
              replacing_metadata == "DRI::Metadata::EncodedArchivalDescriptionComponent"
            fullMetadata.ng_xml = xml_text
            xml_text = split_ead_xml xml_text, replacing_metadata
          end

          descMetadata.ng_xml = xml_text

          return true
        elsif replacing_metadata != nil
          old_digital_object = descMetadata.digital_object
          ds = replacing_metadata.constantize.from_xml xml_text

          # Given that the original and replacing metadata are definitely
          # using different metadata schema, do any of them disallow
          # being interchanged.
          if !ds.interchangeable? || !descMetadata.interchangeable?
            return false
          end

          ds.digital_object = old_digital_object
          ds.instance_variable_set :@dsid, "descMetadata"
          self.add_datastream ds

          return true
        end
      end

      # If this is EAD, put the full XML in fullMetadata and
      # return XML with the component's children removed
      def split_ead_xml xml_text, xml_type

        if (xml_text.is_a? Nokogiri::XML::Document)
          xml = xml_text
        else
          xml = Nokogiri::XML xml_text
        end

        if (xml_type == "DRI::Metadata::EncodedArchivalDescription")
          xml.xpath("/ead/archdesc/dsc/*").remove
        else
          xml.xpath("/*/dsc/*").remove
        end

        return xml
      end

      def synchronize_children_to_metadata
        if self.new_record?
          return
        end
        if descMetadata.class == DRI::Metadata::EncodedArchivalDescription ||
           descMetadata.class == DRI::Metadata::EncodedArchivalDescriptionComponent
           
          metadata_child_index = 0

          prev_obj = nil
          child_obj = nil

          child_obj = Batch.find(solr_name('collection_id', :stored_searchable) => pid,
                                         solr_name('is_first_sibling', :stored_searchable) => "1")

          if child_obj == []
            child_obj = nil
          else
            child_obj = child_obj[0]
          end

          # Find the immediate children of this collection in the metadata
          metadata_children = []

          if descMetadata.class == DRI::Metadata::EncodedArchivalDescription
            metadata_children = fullMetadata.ng_xml.xpath("/ead/archdesc/dsc/*")
          else
            metadata_children = fullMetadata.ng_xml.xpath("/*/dsc/*")
          end

          if metadata_children.empty?
            Batch.find(solr_name('ancestor_id', :stored_searchable) => pid).each do |obj|
              obj.generic_files.each do |file_obj|
                file_obj.delete
              end
              obj.delete
            end
          end

          while metadata_child_index < metadata_children.length do
            metadata_cc = metadata_children[metadata_child_index].xpath('did/unitid/@countrycode')[0].value
            metadata_rc = metadata_children[metadata_child_index].xpath('did/unitid/@repositorycode')[0].value
            metadata_id = metadata_children[metadata_child_index].xpath('did/unitid/@identifier')[0].value


            if child_obj != nil &&
               child_obj.identifier.include?(metadata_id) &&
               child_obj.country_code == metadata_cc &&
               child_obj.repository_code == metadata_rc

              # Metadata identifiers match current child's identifiers
              # we can replace the child's metadata if the replacement metadata differs

              # fullMetadata automatically adds an XML header to the start and an extra "\n" at the end.
              # we have to undo these modifications in order to do the comparison
              clean_fullMetadata = child_obj.fullMetadata.ng_xml.to_s[22..-1]
              clean_fullMetadata = clean_fullMetadata[0..-2]

              # now we can do the comparison
              if metadata_children[metadata_child_index].to_s != clean_fullMetadata

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
            else
              # Create a new child
              new_child = Batch.new :desc_metadata_class => DRI::Metadata::EncodedArchivalDescriptionComponent
              new_child.update_metadata metadata_children[metadata_child_index].to_xml
              new_child.previous_sibling = prev_obj
              new_child.governing_collection = self
              new_child.depositor = depositor
              new_child.status = status
              new_child.ingest_files_from_metadata = ingest_files_from_metadata

              # Don't add new node if it's invalid
              if new_child.valid?
                new_child.save

                # add to queue
                prev_obj = new_child
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
        # else if child != nil and check if child identifier is not in metadata
        #   child = child.next_sibling
        #   delete node and it's children
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
            Batch.find(solr_name('ancestor_id', :stored_searchable) => to_delete.pid).each do |obj|
              obj.generic_files.each do |file_obj|
                file_obj.delete
              end
              obj.delete
            end
            to_delete.delete
          end
        end
      end

      private

      @metadata_class


      def custom_validations
        if descMetadata.class < DRI::Metadata::Base
          results = descMetadata.custom_validations

          if results.empty?
            return true
          else
            results.each do |key, value|
              errors.add(key,value)
            end
            return false
          end
        else
          return true
        end
      end

      def get_metadata_class_from_xml xml_text
        result = nil
        xml = nil

        if (xml_text.is_a? Nokogiri::XML::Document)
          xml = xml_text
        else
          xml = Nokogiri::XML xml_text
        end

        namespace = xml.namespaces
        root_name = xml.root.name

        if namespace.has_value?("http://purl.org/dc/elements/1.1/")
          result = "DRI::Metadata::QualifiedDublinCore"
        elsif namespace.has_value?("http://www.loc.gov/mods/v3")
          result = "DRI::Metadata::MODS"
        elsif xml.internal_subset != nil && xml.internal_subset.name == 'ead'
          result = "DRI::Metadata::EncodedArchivalDescription"
        elsif ['c', 'c1', 'c2', 'c3', 'c4', 'c5', 'c6', 'c7', 'c8', 'c9', 'c10', 'c11', 'c12'].include? root_name
          result = "DRI::Metadata::EncodedArchivalDescriptionComponent"
        end       

        return result
      end

      def reset_metadata_check
        @metadata_class = descMetadata.class
      end

      def load_attributes
        ds_class = ""
        ds = nil

        if (new? && desc_metadata_class != nil)
          # For new objects, check what metadata class was asked for during initialization
          ds_class = @desc_metadata_class.to_s

          if ["DRI::Metadata::QualifiedDublinCore", "DRI::Metadata::MODS",
                 "DRI::Metadata::EncodedArchivalDescription", 
                 "DRI::Metadata::EncodedArchivalDescriptionComponent"].include? ds_class
            ds = ds_class.constantize.new
          else
            ds = DRI::Metadata::QualifiedDublinCore.new
          end
        else
          # When loading the object from Fedora, check what metadata
          # the XML uses and load the correct class.
          ds_class = get_metadata_class_from_xml descMetadata.to_xml
          old_digital_object = descMetadata.digital_object
          unless (ds_class == nil)
            ds = ds_class.constantize.from_xml descMetadata.to_xml
          else
            ds = DRI::Metadata::QualifiedDublinCore.new
          end
          ds.digital_object = old_digital_object
        end

        if (ds != nil)       
          ds.instance_variable_set :@dsid, "descMetadata"
          self.add_datastream ds
        end

        @metadata_class = descMetadata.class
      end

      def synchronize_if_changed
        content_changed = false

        if (self.descMetadata.synchronize_metadata_on_save == true)
          content_changed = self.descMetadata.changed?
        end

        yield
        if content_changed && !new_record?
          Sufia.queue.push(SynchronizeChildrenToMetadataJob.new(self.pid))
        end
      end

      # Indexing object types as a hierarchical tree
      def object_types_to_solr(solr_doc=Hash.new)

        # Add title metadata from parent collections
        object_types = []

        #main_category = nil

        type.each do | curr_category |
          #if DRI::Vocabulary::dcmiType.include? curr_category
            object_types.push curr_category.split.map(&:capitalize)*' '
           # main_category = curr_category
          #else
            # Disable for now
            #if main_category != nil
            #  object_types.push main_category+":"+curr_category
            #end
          #end
        end


        if object_types.empty?
          case descMetadata
          when DRI::Metadata::EncodedArchivalDescriptionComponent
            object_types.push ead_level.split.map(&:capitalize)*' '
          when DRI::Metadata::EncodedArchivalDescription
            object_types.push "Collection"
          end
        end

        if object_types.count < 1
          object_types.push "Unknown"
        end
        solr_doc.merge!(solr_name('object_type', :facetable) => object_types)
        solr_doc.merge!(solr_name('object_type', :displayable) => object_types)
        if rights.empty?
          solr_doc.merge!(solr_name('rights', :stored_searchable) => ['No rights statement'])
        end

        solr_doc
      end

    end
  end
end