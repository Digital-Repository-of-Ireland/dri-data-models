module DRI
  module Metadata
    # A datastream that interacts with MODS.
    class Mods < DRI::Datastreams::OmDatastream
      include DRI::Metadata
      include DRI::Metadata::Terminologies::Mods

      MODS_NS_MAPPING = { 'xmlns:mods' => MODS_NS }.freeze

      # Determine whether the metadata describes a collection
      # Collection if typeOfResource[@collection="yes"]
      def collection?
        mods_type_collection.present?
      end

      # Roles attribute setter
      # @example Sample Hash:
      #   { 'name' => ['Test host', 'new producer'],
      #     'type' => ['role_hst', 'role_pro'],
      #     'authority' => ['lhsc', '']
      #   }
      # @param [Hash] roles hash with metadata marcrelator values
      # @option roles [Array<String>] :name the metadata values for the marcrelators in :type
      # @option roles [Array<String>] :type the marcrelator codes
      # @option roles [Array<String>] :authority the values for the role authority
      def roles=(roles)
        return unless roles.is_a?(Hash)
        return unless required_keys?(roles, 'type', 'name', 'authority')
        return unless same_size?(roles['type'], roles['name'], roles['authority'])

        changed_roles = {}
        roles['type'].uniq.each { |role| changed_roles[role.sub(/^role_/, '')] = [] }

        roles['type'].each_with_index do |role, i|
          next if roles['name'][i].empty?

          role_name = role.sub(/^role_/, '')
          # roles['cre'] = [value, authority]
          changed_roles[role_name].push([roles['name'][i], roles['authority'][i]])
        end

        changed_roles.each_key { |role| add_role(role, changed_roles[role]) }
      end

      # Adds a mods:name element with role information to the XML metadata
      # @see DRI::Metadata::Mods#roles=
      # @param [String] code marc_relator code string
      # @param [Array] value array [value, authority]
      def add_role(code, value)
        return unless DRI::Vocabulary.marc_relators.include?(code)

        xpath = %(/mods:mods/mods:name[mods:role/mods:roleTerm[@type="code"]="#{code}"])
        record = clear_and_get_root(xpath)

        value.each do |elem|
          next if elem.empty? || elem.size != 2 || elem.first.blank?

          name_node = name_template(elem.first, code, DRI::Vocabulary.marc_relators_display[code], elem.last)
          record.add_child(name_node)
        end
      end

      # Returns an empty, default MODS XML template
      #
      # @return [Nokogiri::Document] the MODS XML document
      def self.xml_template
        builder = Nokogiri::XML::Builder.new do |xml|
          xml[MODS_NS_PREFIX].mods(version: '3.5',
                                   'xmlns:xlink' => 'http://www.w3.org/1999/xlink',
                                   'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                                   'xmlns:mods' => MODS_NS,
                                   'xmlns:marcrel' => 'http://www.loc.gov/marc.relators/',
                                   'xmlns:dcterms' => 'http://purl.org/dc/terms/',
                                   "xmlns:#{CR_NS_PREFIX}" => CR_NS,
                                   'xsi:schemaLocation' => MODS_SCHEMA) {
            xml.titleInfo {
              xml.title # title
            }
            # Creator
            xml.name {
              xml.namePart
              xml.role {
                xml.roleTerm('cre', type: 'code', authority: 'marcrelator')
                xml.roleTerm(
                  DRI::Vocabulary.marc_relators_creator['cre'],
                  type: 'text',
                  authority: 'marcrelator'
                )
              }
            }
            # Creation date
            xml.originInfo {
              xml.dateCreated(encoding: 'iso8601') # creation_date
            }
            xml.abstract # description
            xml.subject(authority: '') {
              xml.topic # subject
            }
            xml.accessCondition(type: 'use and reproduction')
            xml.typeOfResource
          }
        end

        builder.doc
      end

      # Override from AF Solrizer for datastreams
      # Update solr_doc Hash for index into Solr from the metadata
      # @param [Hash] solr_doc the solr document hash
      # @param [Hash] opts additional custom options
      # @return [Hash] the updated solr_doc hash for Solr index
      def to_solr(solr_doc = {}, opts = {})
        solr_doc = super(solr_doc, opts)
        SolrIndexer.new(self).build(solr_doc)
      end

      # Transforms all the creation_date metadata values into DCMI Period encoded date strings
      # @return [Array<String>] the array of DCMI Period formatted values for dates
      def creation_date_for_index
        return [] if creation_date.empty? && creation_date_start.empty?

        display_single_date_for_index(creation_date) |
          display_date_range_for_index(creation_date_start, creation_date_end)
      end

      # Returns all metadata related to date for Solr indexing
      # These are date values
      # @return [Array<String>] array of all date metadata values for Solr indexing
      def date_for_index
        display_single_date_for_index(other_date) |
          display_single_date_for_index(part_date) |
          display_date_range_for_index(other_date_start, other_date_end) |
          display_date_range_for_index(part_date_start, part_date_end)
      end

      # Returns all metadata related to people names for Solr indexing
      # People facet
      # @return [Array<String>] array of all people names metadata values for Solr indexing
      def person_array_for_index
        creator | contributor | name_coverage
      end

      # Returns all metadata related to name subjects for Solr indexing
      # These are DRI's Subject (Name) values
      # @return [Array<String>] array of all subject names metadata values for Solr indexing
      def subject_name_for_index
        names_array = []
        query = '/mods:mods/mods:subject/mods:name'
        ng_xml.search(query, MODS_NS_MAPPING).each do |n|
          name_text = n.at('./mods:namePart')
          next if name_text.nil?

          role_text = n.at('./mods:role/mods:roleTerm[@type="text"]')
          names_array << (role_text.nil? ? name_text.content : "#{name_text.content} (#{role_text.content})")
        end

        names_array
      end

      # Returns all metadata related to place/location subjects for Solr indexing
      # These are DRI Subject (Place) values
      # @return [Array<String>] array of all subject place metadata values for Solr indexing
      def subject_place_for_index
        geographical_coverage | mods_hierarchical_geographic | mods_cartographics_scale |
          mods_cartographics_coordinates | mods_cartographics_projection | mods_geographic_code | geocode_logainm
      end

      # Returns all metadata related to temporal subjects for Solr indexing
      # These are DRI Subject (Temporal) values
      # @return [Array<String>] array of all subject temporal metadata values for Solr indexing
      def subject_temporal_for_index
        display_single_date_for_index(temporal_coverage) |
          display_date_range_for_index(subject_date_start, subject_date_end)
      end

      # Transforms an array of individual dates into DCMI period encoded for indexing into Solr
      # No date ranges here, single date display (just the year)
      # @param [Array<String>] date_field the metadata values for dates
      # @return [Array<String>] the array of DCMI Period formatted values for dates
      def display_single_date_for_index(date_field = [])
        date_field.collect do |value|
          if Utils.valid_uri?(value)
            value
          else
            begin
              display_date = ISO8601::DateTime.new(value).strftime('%b %d, %Y')
              DRI::Metadata::Transformations.create_dcmi_period(display_date, value)
            rescue ISO8601::Errors::StandardError
              # DCMI Period 'name' is the md value
              DRI::Metadata::Transformations.create_dcmi_period(value)
            end
          end
        end
      end

      # Transforms arrays of start and end dates into DCMI period encoded for indexing into Solr
      # Display of date ranges: start_year - end_year
      # @param [Array<String>] date_start the metadata values for start dates
      # @param [Array<String>] date_end the metadata values for end dates
      # @return [Array<String>] the array of DCMI Period formatted values for dates
      def display_date_range_for_index(date_start = [], date_end = [])
        date_start.collect.with_index do |name, idx|
          d_start = ISO8601::DateTime.new(name).strftime('%b %d, %Y')

          if date_start.size == date_end.size
            d_end = ISO8601::DateTime.new(date_end[idx]).strftime('%b %d, %Y')
            DRI::Metadata::Transformations.create_dcmi_period("#{d_start} - #{d_end}", name, date_end[idx])
          else
            DRI::Metadata::Transformations.create_dcmi_period(d_start, name)
          end
        rescue ISO8601::Errors::StandardError
          DRI::Metadata::Transformations.create_dcmi_period(name) # DCMI Period 'name' is the md value
        end
      end

      # Return all date ranges formatted in the right format for indexing and single dates
      # Format: start_date/end_date (ISO8601)
      # @return [Hash] the hash with all the dates present in the metadata to be indexed as date ranges
      def date_ranges_for_index
        {
          'creation_date' => date_pairs(creation_date_start, creation_date_end) | creation_date,
          'captured_date' => date_pairs(captured_date_start, captured_date_end) | captured_date,
          'issued_date' => date_pairs(issued_date_start, issued_date_end) | published_date,
          'subject_date' => date_pairs(subject_date_start, subject_date_end) | temporal_coverage,
          'date_other' => date_pairs(other_date_start, other_date_end) | other_date,
          'part_date' => date_pairs(part_date_start, part_date_end) | part_date
        }.reject { |_k, v| v.empty? }
      end

      # Returns an array of types from the metadata (capitalised)
      # @return [Array<String>] the array of type values for Solr indexing
      def type_of_resource
        # mods:typeOfResource last
        # Return also mods:genre values as Types if object is a collection of mods:typeOfResource is not present
        return mods_genre.map(&:capitalize) | resource_type.map(&:capitalize) if mods_type_collection.present? || !resource_type.present?

        resource_type.map(&:capitalize)
      end

      # Creates MODS name XML elements from an array of metadata values.
      # Updates every mods:name (for creators)
      # @see DRI::Mods#creator=
      # @example Sample Hash:
      #   { display: ['Test creator'], role: ['aut'], authority: ['lhsc'] }
      # @param [Hash] creators the attributes and content required to create a mods:name element for creator
      # @option creators [Array<String>] :display the content for the node
      # @option creators [Array<String>] :role the role attribute for the node
      # @option creators [Array<String>] :authority the value for the authority attribute of the mods:name element
      def add_creator(creators)
        add_person_names(creators, DRI::Vocabulary.marc_relators_creator)
      end

      # Creates MODS name XML elements from an array of metadata values.
      # Updates every mods:name (for contributors)
      # @see DRI::Mods#contributor=
      # @example Sample Hash:
      #   { display: ['Test contributor'], role: ['ctb'], authority: ['lhsc'] }
      # @param [Hash] contributors the attributes and content required to create a mods:name element for contributor
      # @option contributors [Array<String>] :display the content for the node
      # @option contributors [Array<String>] :role the role attribute for the node
      # @option contributors [Array<String>] :authority the value for the authority attribute of the mods:name element
      def add_contributor(contributors)
        add_person_names(contributors, DRI::Vocabulary.marc_relators_contributor)
      end

      # Shared by add_creator/add_contributor
      # @param [Hash] hash the :display/:role/:authority attributes, as per add_creator/add_contributor
      # @param [Hash] relator_map DRI::Vocabulary.marc_relators_creator or marc_relators_contributor
      def add_person_names(hash, relator_map)
        return unless hash.is_a?(Hash)
        return unless required_keys?(hash, :display, :role, :authority)
        return unless same_size?(hash[:display], hash[:role], hash[:authority])

        valid_roles = relator_map.keys

        valid_roles.each do |key|
          xpath = %(/mods:mods/mods:name[mods:role/mods:roleTerm[@type='code' and @authority='marcrelator' and text()='#{key}']])
          ng_xml.search(xpath, MODS_NS_MAPPING).each(&:remove)
        end

        record = ng_xml.root

        hash[:display].each_with_index do |elem, idx|
          next if elem.empty? || !valid_roles.include?(hash[:role][idx])

          name = name_template(elem, hash[:role][idx], relator_map[hash[:role][idx]], hash[:authority][idx])
          record.add_child(name)
        end
      end

      # Creates MODS elements within mods:originInfo XML elements from an array of metadata values
      # Updates every mods:originInfo (for Origination Information: dates, publisher... see MODS Schema)
      # @see DRI::Mods#origin_metadata=
      # @example Sample Hash:
      #   [{ '0' => { tag: 'dateCreated', start: '18930101', end: '19721231', encoding: 'iso8601' },
      #      '1' => { tag: 'dateIssued', start: '1972', end: '', encoding: 'iso8601' } },
      #    { '0' => { tag: 'publisher', content: 'Publisher name 1' } }]
      # @param [Array<Hash>] origin the attributes and content required to create a any sub-elements nested within mods:originInfo
      def add_origin_metadata(origin)
        return unless origin.is_a?(Array)

        record = clear_and_get_root('/mods:mods/mods:originInfo')

        origin.each do |origin_elem|
          origin_node = Nokogiri::XML::Node.new('mods:originInfo', ng_xml)

          origin_elem.each do |_key, elem|
            tag = elem[:tag]
            next if tag.nil? || tag.empty? || !DRI::Vocabulary.mods_origin_info_tags.include?(tag)

            case tag
            when 'place'
              if elem[:content].present?
                node = Nokogiri::XML::Node.new('mods:place', ng_xml)
                p_term = Nokogiri::XML::Node.new('mods:placeTerm', ng_xml)
                p_term.content = elem[:content]
                node.add_child(p_term)
                origin_node.add_child(node)
              end
            when 'issuance', 'publisher', 'edition', 'frequency'
              if elem[:content].present?
                node = Nokogiri::XML::Node.new("#{MODS_NS_PREFIX}:#{tag}", ng_xml)
                node.content = elem[:content]
                origin_node.add_child(node)
              end
            else
              # date
              dates_array = date_template(tag, elem[:encoding], elem[:start], elem[:end])
              next if dates_array.nil?

              origin_node.add_child(dates_array.first)
              origin_node.add_child(dates_array.last) if dates_array.size > 1
            end
          end # elems from each origin info node

          record.add_child(origin_node) unless origin_node.children.empty?
        end # iterate over all origin info nodes
      end

      # Creates MODS elements within mods:accessCondition XML elements from an array of metadata values
      # Updates every mods:accessCondition (for Rights)
      # @see DRI::Mods#rights=
      # @example Sample Hash:
      #   { status: ['copyrighted'], rights: ['All rigths reserved'], note: [''] }
      # @param [Hash] statement the attributes and content required to create a mods:accessCondition element for rights
      # @option statement [Array<String>] :rights the content for the copyrightMD:copyright node
      # @option statement [Array<String>] :note the content for the copyrightMD:note element
      # @option statement [Array<String>] :status the value for the copyright.status attribute of the copyrightMD:copyright element
      def add_rights(statement)
        return unless statement.is_a?(Hash)
        return unless required_keys?(statement, :status, :rights, :note)
        return unless same_size?(statement[:status], statement[:rights], statement[:note])

        record = clear_and_get_root('/mods:mods/mods:accessCondition')

        statement[:rights].each_with_index do |elem, idx|
          next if elem.empty?

          rnode = rights_template(elem, statement[:note][idx], statement[:status][idx])
          record.add_child(rnode)
        end
      end

      # Create the XML nodes for subject terms within the MODS metadata
      # @example Sample Hash:
      #   [{ values: [{ tag: 'topic', content: 'Stained glass' },
      #               { tag: 'temporal', start: '18900101', end: '19721231', encoding: 'w3cdtf' },
      #               { tag: 'temporal', start: '20150101', end: '', encoding: 'iso8601' }], authority: 'lcsh' },
      #    { values: [{ tag: 'topic', content: 'Correspondence' },
      #               { tag: 'name', display: 'St. Agnes of Montepulciano', role: 'pat', authority: '' }], authority: 'local' }]
      # @param [Hash] subjects the hash of metadata values for subject terms
      # @option subjects [Array<String>] :authority the authority name for the subject element
      # @option subjects [Array<Hash>] :values the hash of subject elements
      # @option values [Array<String>] :tag the tag name for the subject element
      # @option values [Array<String>] :content the content for the subject node
      def add_subject(subjects)
        return unless subjects.is_a?(Array)
        return unless subjects.all? { |subj| required_keys?(subj, :values, :authority) }

        record = clear_and_get_root('/mods:mods/mods:subject')

        subjects.each do |subj|
          next if subj[:values].empty?

          subject_node = Nokogiri::XML::Node.new('mods:subject', ng_xml)
          subject_node['authority'] = subj[:authority] unless subj[:authority].empty?

          subj[:values].each do |node|
            next unless node.key?(:tag)

            n = nil

            case node[:tag]
            when 'topic'
              next unless node.key?(:content)

              n = Nokogiri::XML::Node.new('mods:topic', ng_xml)
              n.content = node[:content]
            when 'name'
              next unless required_keys?(node, :display, :role)

              n = name_template(node[:display], node[:role], DRI::Vocabulary.marc_relators_display[node[:role]], node[:authority])
            when 'temporal'
              next unless required_keys?(node, :start, :end, :encoding)

              dates_array = date_template('temporal', node[:encoding], node[:start], node[:end])
              next if dates_array.nil?

              subject_node.add_child(dates_array.first)
              subject_node.add_child(dates_array.last) if dates_array.size > 1
            when 'geographic'
              next unless node.key?(:content)

              n = Nokogiri::XML::Node.new('mods:geographic', ng_xml)
              if node[:uri].present?
                n['authority'] = 'logainm'
                n['valueURI'] = node[:uri]
              end
              n.content = node[:content]
            else
              next
            end

            subject_node.add_child(n) unless n.nil? || n.content.empty?
          end # iterate over subjects

          record.add_child(subject_node) unless subject_node.children.empty?
        end
      end

      # Creates MODS type XML elements from a Hash of metadata values.
      # Updates every mods:typeOfResource element
      # @see DRI::Mods#type=
      # @example Sample Hash:
      #   { content: ['collections (object groupings)', 'Photographs'], collection: true }
      # @param [Hash] types hash of genre metadata values to set
      # @option types [Array<String>] :content the array of metadata genre values
      # @option types [Array<String>] :collection flag to specify whether the type is collection
      def add_type(types)
        return unless types.is_a?(Hash)
        return unless required_keys?(types, :collection, :content)

        record = clear_and_get_root('/mods:mods/mods:typeOfResource')

        collection_set = false
        types[:content].each do |elem|
          next if elem.empty? || !DRI::Vocabulary.mods_type_resource_values.include?(elem)

          type_node = Nokogiri::XML::Node.new('mods:typeOfResource', ng_xml)
          unless collection_set
            type_node['collection'] = 'yes' if types[:collection]
            collection_set = true
          end
          type_node.content = elem
          record.add_child(type_node)
        end
      end

      # Creates MODS genre XML elements from a Hash of metadata values.
      # Updates every genre element
      # @see DRI::Mods#mods_genre=
      # @example Sample Hash:
      #   { authority: ['aat', ''], content: ['collections (object groupings)', 'Photographs'] }
      # @param [Hash] genres hash of genre metadata values to set
      # @option genres [Array<String>] :content the array of metadata genre values
      # @option genres [Array<String>] :authority the array of value for the elements' authority attribute
      def add_mods_genre(genres)
        return unless genres.is_a?(Hash)
        return unless required_keys?(genres, :content, :authority)

        record = clear_and_get_root('/mods:mods/mods:genre')

        genres[:content].each_with_index do |elem, idx|
          next if elem.empty?

          genre_node = Nokogiri::XML::Node.new('mods:genre', ng_xml)
          genre_node.content = elem
          genre_node['authority'] = genres[:authority][idx] unless genres[:authority][idx].empty?
          record.add_child(genre_node)
        end
      end

      # Creates MODS language XML elements from an array of metadata values.
      # Updates every language element (language metadata)
      # @see DRI::Mods#language=
      # @param [Array<String>] languages array of language metadata values to set
      def add_language(languages)
        record = clear_and_get_root('/mods:mods/mods:language')

        languages.each do |lang|
          lang_node = Nokogiri::XML::Node.new('mods:language', ng_xml)
          lang_code = Nokogiri::XML::Node.new('mods:languageTerm', ng_xml)
          lang_code['type'] = 'code'
          lang_code.content = DRI::Metadata::Descriptors.standardise_language_code(lang)
          lang_text = Nokogiri::XML::Node.new('mods:languageTerm', ng_xml)
          lang_text['type'] = 'text'
          lang_text.content = lang

          lang_node.add_child(lang_code)
          lang_node.add_child(lang_text)
          record.add_child(lang_node)
        end
      end

      # Creates an array of MODS names elemnts
      # @param [String] content the value for the element's content
      # @param [String] code the value for the mods:roleTerm marcrelator code
      # @param [String] text the value for the mods:roleTerm marcrelator text term
      # @param [String] authority the value of the authority attribute for the MODS name element
      # @return [Array<Nokogiri::XML::Node>] the array of MODS people/names XML nodes
      def name_template(content, code, text, authority = nil)
        name = Nokogiri::XML::Node.new('mods:name', ng_xml)
        name['authority'] = authority unless authority.nil? || authority.empty?
        name_part = Nokogiri::XML::Node.new('mods:namePart', ng_xml)
        name_part.content = content

        unless DRI::Vocabulary.marc_relators_display.key?(code)
          name.add_child(name_part)
          return name
        end

        role_node = Nokogiri::XML::Node.new('mods:role', ng_xml)
        role_code = Nokogiri::XML::Node.new('mods:roleTerm', ng_xml)
        role_code['type'] = 'code'
        role_code['authority'] = 'marcrelator'
        role_code.content = code
        role_text = Nokogiri::XML::Node.new('mods:roleTerm', ng_xml)
        role_text['type'] = 'text'
        role_text['authority'] = 'marcrelator'
        role_text.content = text

        name.add_child(name_part)
        role_node.add_child(role_code)
        role_node.add_child(role_text)
        name.add_child(role_node)

        name
      end

      # Creates an array of MODS dates elemnts
      # @param [String] tag the name of the tag to use for the dates being added
      # @param [String] enc the value for encoding attribute of the dates being added
      # @param [String] sdate the value for the start date value for the element
      # @param [String] edate the value for the end date value for the element
      # @return [Array<Nokogiri::XML::Node>] the array of MODS date XML nodes
      def date_template(tag, enc, sdate, edate = nil)
        return nil unless DRI::Vocabulary.mods_date_tags.include?(tag) && !sdate.empty?

        start_date = Nokogiri::XML::Node.new("#{MODS_NS_PREFIX}:#{tag}", ng_xml)
        start_date['point'] = 'start' unless edate.nil? || edate.empty?
        start_date['encoding'] = enc unless enc.empty? || !DRI::Vocabulary.mods_date_encoding.include?(enc)
        start_date.content = sdate

        unless edate.nil? || edate.empty?
          end_date = Nokogiri::XML::Node.new("#{MODS_NS_PREFIX}:#{tag}", ng_xml)
          end_date['point'] = 'end'
          end_date['encoding'] = enc unless enc.empty? || !DRI::Vocabulary.mods_date_encoding.include?(enc)
          end_date.content = edate

          return [start_date, end_date]
        end

        [start_date]
      end

      # Creates a mods:accessCondition element template and returns the newly created node
      # @param [String] content the value for the element's content
      # @param [String] note the value for the note element's content
      # @param [String] status the value for copyright.status attribute in the element
      # @return [Nokogiri::XML::Node] the mods:accessCondition node
      def rights_template(content, note = '', status = '')
        rights_node = Nokogiri::XML::Node.new("#{MODS_NS_PREFIX}:accessCondition", ng_xml)
        rights_node['type'] = 'use and reproduction'

        copyright_md = Nokogiri::XML::Node.new("#{CR_NS_PREFIX}:copyright", ng_xml)
        copyright_md['copyright.status'] = status unless status.empty?
        holder = Nokogiri::XML::Node.new("#{CR_NS_PREFIX}:rights.holder", ng_xml)
        holder.content = content
        copyright_md.add_child(holder)

        unless note.empty?
          rights_note = Nokogiri::XML::Node.new("#{CR_NS_PREFIX}:general.note", ng_xml)
          rights_note.content = note
          copyright_md.add_child(rights_note)
        end

        rights_node.add_child(copyright_md)

        rights_node
      end

      # Returns a Hash with all the values for the DRI editable metadata fields
      # to be populated in a UI Edit form
      # @see DRI::Mods#retrieve_hash_attributes
      # @example Sample return hash:
      #   { title: ['Clarke Studios: Photographs'],
      #     desc_abstract: ['Clarke Studios: Photographs is a subsection of the Clarke Stained Glass Studios Collection'],
      #     desc_note: ['Test note'],
      #     desc_toc: ['Test table of contents'],
      #     desc_physdesc_note: ['Note under physical description'],
      #     rights: ['Copyright 2015 The Board of Trinity College Dublin. '],
      #     origin_metadata: [{ '0' => { tag: 'dateCreated', start: '18930101', end: '19721231', encoding: 'iso8601' },
      #                         '1' => { tag: 'dateIssued', start: '1972', end: '', encoding: 'iso8601' } },
      #                       { '0' => { tag: 'publisher', content: 'Publisher name 1' } }],
      #     subject_metadata: @subjects_hash,
      #     type: { collection: true, content: ['mixed material']},
      #     mods_genre: { authority: ['aat', ''], content: ['collections (object groupings)', 'Photographs'] },
      #     language: ['English'],
      #     roles: { 'name' => ['Test host', 'new producer'],
      #              'type' => ['role_hst', 'role_pro'],
      #              'authority' => ['lhsc', ''] }
      #   }
      #
      # @example And @subjects_hash is an Array of:
      #   [{ values: [{ tag: 'topic', content: 'Stained glass' },
      #                { tag: 'temporal', start: '18900101', end: '19721231', encoding: 'w3cdtf' },
      #                { tag: 'temporal', start: '20150101', end: '', encoding: 'iso8601' }], authority: 'lcsh' },
      #     { values: [{ tag: 'topic', content: 'Correspondence' },
      #                { tag: 'name', display: 'St. Agnes of Montepulciano', role: 'pat' },
      #                { tag: 'geographic', content: 'Killeshandra', uri: 'http://data.logainm.ie/place/5104' }], authority: 'local' }]
      # ]
      # @return [Hash] Hash of DRI MODS metadata
      def retrieve_terms_hash
        TermsHashExtractor.new(self).call
      end

      # Looks all dates included in a given mods:originInfo element and determines whether
      # they are all iso8601 or w3cdtf encoded, and valid
      #
      # @param [Nokogiri::Node] origin_node the mods:originInfo node to validate
      # @param [Nokogiri::Node] date_tag the name of the date tag to validate
      # @return [Boolean] true if valid, encoded dates; false otherwise
      def validate_dates(origin_node, date_tag)
        date_nodes = origin_node.children.select { |node| node.local_name == date_tag }

        return true if date_nodes.empty?

        start_count = 0
        end_count = 0
        date_nodes.each do |date|
          start_count += 1 unless date['point'] == 'start'
          end_count += 1 unless date['point'] == 'end'

          break if start_count > 1 || end_count > 1
        end

        start_count == end_count && start_count <= 1
      end

      # Looks all dates included in all mods:originInfo elements and determines whether
      # they are all iso8601 or w3cdtf encoded, and valid
      # @return [Boolean] true if valid, encoded dates; false otherwise
      def validate_all_dates
        origin_nodes = ng_xml.search('//mods:originInfo', MODS_NS_MAPPING)

        origin_nodes.each do |node|
          valid_created = validate_dates(node, 'mods:dateCreated')
          valid_issued = validate_dates(node, 'mods:dateIssued')

          if !valid_created || !valid_issued
            Rails.logger.error('MODS validate_all_dates: invalid date found in metadata record.')
            return false
          end
        end

        true
      end

      # Implement additional DRI metadata validations as this class does not inherit
      # from DRI::Metadata::Base
      # @return [Hash] the hash with any errors from validation
      def custom_validations
        Validator.new(self).call
      end # custom_validations

      load_inherited_terminology

      private

      def required_keys?(hash, *keys)
        keys.all? { |key| hash.key?(key) }
      end

      def same_size?(*arrays)
        arrays.map(&:size).uniq.size <= 1
      end

      # search-then-remove-existing-nodes.
      # @return [Nokogiri::XML::Node] the document root, ready for new children to be added
      def clear_and_get_root(xpath)
        ng_xml.search(xpath, MODS_NS_MAPPING).each(&:remove)
        ng_xml.root
      end

      def date_pairs(starts, ends)
        starts.map.with_index { |name, idx| starts.size == ends.size ? "#{name}/#{ends[idx]}" : name }
      end
    end # class
  end # module
end # module
