module DRI
  module Metadata
    # An ActiveFedora datastream that interacts with MODS.
    class Mods < DRI::Metadata::Base
      include DRI::Metadata::Terminologies::Mods

      # Determine whether the metadata describes a collection
      # Collection if typeOfResource[@collection="yes"]
      def collection?
        mods_type_collection.present? ? true : false
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
        return unless roles.is_a?(Hash) &&
                      roles.key?('type') &&
                      roles.key?('name') &&
                      roles.key?('authority') &&
                      roles['type'].size == roles['name'].size &&
                      roles['name'].size == roles['authority'].size

        changed_roles = {}
        roles['type'].uniq.each { |role| changed_roles[role.sub(/^role_/, '')] = [] }

        roles['type'].each_with_index do |role, i|
          next if roles['name'][i].empty?

          role_name = role.sub(/^role_/, '')
          # roles['cre'] = [value, authority]
          changed_roles[role_name].push([roles['name'][i], roles['authority'][i]])
        end

        changed_roles.keys.each { |role| add_role(role, changed_roles[role]) }
      end

      # Adds a mods:name element with role information to the XML metadata
      # @see DRI::Metadata::Mods#roles=
      # @param [String] code marc_relator code string
      # @param [Array] value array [value, authority]
      def add_role(code, value)
        return if !DRI::Vocabulary.marc_relators.include?(code)
        xpath = "/mods:mods/mods:name[mods:role/mods:roleTerm[@type=\"code\"]=\"#{code}\"]"
        ng_xml.search(xpath, { 'xmlns:mods' => MODS_NS }).each(&:remove)

        record = ng_xml.root
        value.each do |elem|
          next if elem.empty? || elem.size != 2 || elem.first.blank?

          name_node = name_template(elem.first, code,
                                    DRI::Vocabulary.marc_relators_display[code],
                                    elem.last)

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

        # Title_sorted - A SOLR index for sorting titles
        if title.length > 0
          sorted_title = DRI::Metadata::Transformations.transform_title_for_sort(title[0])

          unless sorted_title.empty?
            solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('title_sorted', :stored_sortable, type: :string) => [sorted_title])
          end
        end

        # Type
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('type', :stored_searchable) => type_for_index)
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('type', :facetable) => type_for_index)
        if collection?
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('type', :stored_searchable, type: :string) => 'Collection')
        end

        # MODS has several "name" tags, so we merge them together into the SOLR document
        person_array = person_array_for_index

        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('person', :facetable) => person_array)
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('person', :stored_searchable, type: :text) => person_array | DRI::Metadata::Transformations.transform_name(person_array))

        # all_metadata - A SOLR index of all the text contained in the XML document
        all_metadata = ''
        ng_xml.xpath('//text()').each do |text_node|
          all_metadata += text_node.text
          all_metadata += ' '
        end
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('all_metadata', :stored_searchable, type: :text) => [all_metadata])

        # Subject
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('subject', :stored_searchable) => subject) unless subject == []
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('subject', :facetable) => subject) unless subject == []

        subject_place_array = subject_place_for_index
        subject_temporal_array = subject_temporal_for_index

        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('name_coverage', :stored_searchable) => subject_name_for_index) unless name_coverage.empty?
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('name_coverage', :facetable) => subject_name_for_index) unless name_coverage.empty?

        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('geographical_coverage', :stored_searchable) => subject_place_array) unless subject_place_array.empty?
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('geographical_coverage', :facetable) => filter_uris(subject_place_array)) unless subject_place_array.empty?

        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('temporal_coverage', :stored_searchable) => subject_temporal_array) unless subject_temporal_array.empty?
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('temporal_coverage', :facetable) => filter_uris(subject_temporal_array)) unless subject_temporal_array.empty?

        # Indices for external relationships (to be displayed as URL)
        external_rels = *(DRI::Vocabulary.mods_relationship_types.map { |s| s.prepend('ext_related_items_ids_').to_sym })

        external_rels.each do |elem|
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name(elem, :stored_searchable) => send(elem)) unless send(elem) == []
        end

        # Index creation_date
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('creation_date', :stored_searchable) => creation_date_for_index)

        # Index creation_date
        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('date', :stored_searchable) => date_for_index)

        # Index Published Date
        unless published_date.empty? && issued_date_start.empty?
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('published_date', :stored_searchable) => display_single_date_for_index(published_date) |
                              display_date_range_for_index(issued_date_start, issued_date_end))
        end

        # Index date ranges
        date_ranges = date_ranges_for_index # ALL the date ranges
        # Creation date dateRange index
        cdate_ranges = date_ranges.select { |key, _value| ['creation_date', 'captured_date'].include?(key) }
        cdate_index = DRI::Metadata::Transformations.transform_date_ranges(cdate_ranges)
        if cdate_index.present?
          solr_doc.merge!(DRI::Metadata::Transformations::CREATION_DATE_RANGE_SOLR_FIELD => cdate_index)
          cdate_years = DRI::Metadata::Transformations.date_range_years(cdate_index)
          solr_doc.merge!(DRI::Metadata::Transformations::CREATION_DATE_YEAR_SOLR_FIELD => cdate_years)
          solr_doc.merge!(DRI::Metadata::Transformations::CREATION_DATE_RANGE_START_SOLR_FIELD => cdate_years.min)
          solr_doc.merge!(DRI::Metadata::Transformations::CREATION_DATE_RANGE_END_SOLR_FIELD => cdate_years.max)
        end

        # Published date dateRange index
        pdate_ranges = date_ranges.select { |key, _value| ['issued_date'].include?(key) }
        pdate_index = DRI::Metadata::Transformations.transform_date_ranges(pdate_ranges)
        if pdate_index.present?
          solr_doc.merge!(DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_SOLR_FIELD => pdate_index)
          pdate_years = DRI::Metadata::Transformations.date_range_years(pdate_index)
          solr_doc.merge!(DRI::Metadata::Transformations::PUBLISHED_DATE_YEAR_SOLR_FIELD => pdate_years)
          solr_doc.merge!(DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_START_SOLR_FIELD => pdate_years.min)
          solr_doc.merge!(DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_END_SOLR_FIELD => pdate_years.max)
        end

        # date dateRange index
        ddate_ranges = date_ranges.select { |key, _value| ['date_other', 'part_date'].include?(key) }
        ddate_index = DRI::Metadata::Transformations.transform_date_ranges(ddate_ranges)
        if ddate_index.present?
          solr_doc.merge!(DRI::Metadata::Transformations::DATE_RANGE_SOLR_FIELD => ddate_index)
          ddate_years = DRI::Metadata::Transformations.date_range_years(ddate_index).minmax
          solr_doc.merge!(DRI::Metadata::Transformations::DATE_RANGE_START_SOLR_FIELD => ddate_years[0])
          solr_doc.merge!(DRI::Metadata::Transformations::DATE_RANGE_END_SOLR_FIELD => ddate_years[1])
        end

        # Subject date dateRange index
        sdate_ranges = date_ranges.select { |key, _value| ['subject_date'].include?(key) }
        sdate_index = DRI::Metadata::Transformations.transform_date_ranges(sdate_ranges)
        if sdate_index.present?
          solr_doc.merge!(DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_SOLR_FIELD => sdate_index)
          sdate_years = DRI::Metadata::Transformations.date_range_years(sdate_index).minmax
          solr_doc.merge!(DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_START_SOLR_FIELD => sdate_years[0])
          solr_doc.merge!(DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_END_SOLR_FIELD => sdate_years[1])
        end

        # Geospatial indexing
        geospatial_hash = DRI::Metadata::Transformations.transform_geospatial(
          {
            'geographical_coverage' => geographical_coverage.reject{ |i| i[/\A#{URI.regexp(['http', 'https'])}\z/] }
          }
        )

        # Index logainm URIs in the appropriate geographic indices
        uris = geocode_logainm.select { |i| i[/\A#{URI.regexp(['http', 'https'])}\z/] } | reconciliation_uris
        if uris.present?
          linked_data = DRI::Metadata::Transformations.transform_geospatial({ 'geographical_coverage' => uris })

          geospatial_hash[:coords].concat(linked_data[:coords])
          geospatial_hash[:name].concat(linked_data[:name])
          geospatial_hash[:json].concat(linked_data[:json])
        end

        solr_doc.merge!(DRI::Metadata::Transformations::GEOSPATIAL_SOLR_FIELD => geospatial_hash[:coords]) unless geospatial_hash[:coords].empty?

        unless geospatial_hash[:name].empty?
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name(DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD, :stored_searchable) => geospatial_hash[:name])
          solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name(DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD, :facetable, type: :text) => geospatial_hash[:name])
        end

        solr_doc.merge!(ActiveFedora.index_field_mapper.solr_name('geojson', :stored_searchable, type: :symbol) => geospatial_hash[:json]) unless geospatial_hash[:json].empty?

        solr_doc
      end

      # Transforms all the creation_date metadata values into DCMI Period encoded date strings
      # @return [Array<String>] the array of DCMI Period formatted values for dates
      def creation_date_for_index
        unless creation_date.empty? && creation_date_start.empty?
          return display_single_date_for_index(creation_date) |
                 display_date_range_for_index(creation_date_start, creation_date_end)
        end

        []
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
        ng_xml.search(query, { 'xml:mods' => MODS_NS }).each do |n|
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
        date_range_display = date_start.collect.with_index do |name, idx|
          begin
            d_start = ISO8601::DateTime.new(name).strftime('%b %d, %Y')

            if date_start.size == date_end.size
              d_end = ISO8601::DateTime.new(date_end[idx]).strftime('%b %d, %Y')
              DRI::Metadata::Transformations.create_dcmi_period(d_start << ' - ' << d_end, name, date_end[idx])
            else
              Transformations.create_dcmi_period(d_start, name)
            end
          rescue ISO8601::Errors::StandardError
            DRI::Metadata::Transformations.create_dcmi_period(name) # DCMI Period 'name' is the md value
          end
        end

        date_range_display
      end

      # Return all date ranges formatted in the right format for indexing and single dates
      # Format: start_date/end_date (ISO8601)
      # @return [Hash] the hash with all the dates present in the metadata to be indexed as date ranges
      def date_ranges_for_index
        dates_hash = {}

        creation_date_array = creation_date_start.map.with_index { |name, idx| creation_date_start.size == creation_date_end.size ? ("#{name}/#{creation_date_end[idx]}") : name }
        captured_date_array = captured_date_start.map.with_index { |name, idx| captured_date_start.size == captured_date_end.size ? ("#{name}/#{captured_date_end[idx]}") : name }
        issued_date_array = issued_date_start.map.with_index { |name, idx| issued_date_start.size == issued_date_end.size ? ("#{name}/#{issued_date_end[idx]}") : name }
        subject_date_array = subject_date_start.map.with_index { |name, idx| subject_date_start.size == subject_date_end.size ? ("#{name}/#{subject_date_end[idx]}") : name }
        date_other_array = other_date_start.map.with_index { |name, idx| other_date_start.size == other_date_end.size ? ("#{name}/#{other_date_end[idx]}") : name }
        part_date_array = part_date_start.map.with_index { |name, idx| part_date_start.size == part_date_end.size ? ("#{name}/#{part_date_end[idx]}") : name }

        dates_hash['creation_date'] = creation_date_array | creation_date
        dates_hash['captured_date'] = captured_date_array | captured_date
        dates_hash['issued_date'] = issued_date_array | published_date
        dates_hash['subject_date'] = subject_date_array | temporal_coverage
        dates_hash['date_other'] = date_other_array | other_date
        dates_hash['part_date'] = part_date_array | part_date

        dates_hash.delete_if { |_k, v| v.empty? }
      end

      # Returns an array of types from the metadata (capitalised)
      # @return [Array<String>] the array of type values for Solr indexing
      def type_for_index
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
        return unless creators.is_a? Hash

        valid_keys = [:display, :role, :authority].all? { |s| creators.key? s }
        return unless valid_keys && creators[:display].size == creators[:role].size && creators[:role].size == creators[:authority].size

        marc_creator_keys = DRI::Vocabulary.marc_relators_creator.keys

        marc_creator_keys.each do |key|
          xpath = "/mods:mods/mods:name[mods:role/mods:roleTerm[@type='code' and @authority='marcrelator' and text()='#{key}']]"
          ng_xml.search(xpath, { 'xmlns:mods' => MODS_NS }).each(&:remove)
        end

        record = ng_xml.root

        creators[:display].each_with_index do |elem, idx|
          next if elem.empty? || !marc_creator_keys.include?(creators[:role][idx])

          name = name_template(elem,
                               creators[:role][idx],
                               DRI::Vocabulary.marc_relators_creator[creators[:role][idx]],
                               creators[:authority][idx])
          record.add_child(name)
        end
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
        return unless contributors.is_a? Hash

        valid_keys = [:display, :role, :authority].all? { |s| contributors.key? s }
        return unless valid_keys && contributors[:display].size == contributors[:role].size && contributors[:role].size == contributors[:authority].size

        marc_ctb_keys = DRI::Vocabulary.marc_relators_contributor.keys

        marc_ctb_keys.each do |key|
          xpath = "/mods:mods/mods:name[mods:role/mods:roleTerm[@type='code' and @authority='marcrelator' and text()='#{key}']]"
          ng_xml.search(xpath, { 'xmlns:mods' => MODS_NS }).each(&:remove)
        end

        record = ng_xml.root

        contributors[:display].each_with_index do |elem, idx|
          next if elem.empty? || !marc_ctb_keys.include?(contributors[:role][idx])

          name = name_template(elem,
                               contributors[:role][idx],
                               DRI::Vocabulary.marc_relators_contributor[contributors[:role][idx]],
                               contributors[:authority][idx])
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
        return unless origin.is_a? Array

        xpath = '/mods:mods/mods:originInfo'
        ng_xml.search(xpath, { 'xmlns:mods' => MODS_NS }).each(&:remove)

        record = ng_xml.root
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
        return unless statement.is_a? Hash

        valid_keys = [:status, :rights, :note].all? { |s| statement.key? s }
        return unless valid_keys && statement[:status].size == statement[:rights].size && statement[:rights].size == statement[:note].size

        xpath = '/mods:mods/mods:accessCondition'
        ng_xml.search(xpath, { 'xmlns:mods' => MODS_NS }).each(&:remove)

        record = ng_xml.root

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
        return unless subjects.is_a? Array

        valid_hash = subjects.all? { |subj| [:values, :authority].all? { |s| subj.key? s } }
        return unless valid_hash

        xpath = '/mods:mods/mods:subject'
        ng_xml.search(xpath, { 'xmlns:mods' => MODS_NS }).each(&:remove)

        record = ng_xml.root

        subjects.each do |subj|
          next if subj[:values].empty?

          subject_node = Nokogiri::XML::Node.new('mods:subject', ng_xml)
          subject_node['authority'] = subj[:authority] unless subj[:authority].empty?

          subj[:values].each do |node|
            next unless node.key? :tag

            case node[:tag]
            when 'topic'
              next unless node.key? :content
              n = Nokogiri::XML::Node.new('mods:topic', ng_xml)
              n.content = node[:content]
            when 'name'
              next unless [:display, :role].all? { |s| node.key? s }
              n = name_template(node[:display],
                                node[:role],
                                DRI::Vocabulary.marc_relators_display[node[:role]],
                                node[:authority])
            when 'temporal'
              next unless [:start, :end, :encoding].all? { |s| node.key? s }
              dates_array = date_template('temporal', node[:encoding],
                                          node[:start], node[:end])
              next if dates_array.nil?
              subject_node.add_child(dates_array.first)
              subject_node.add_child(dates_array.last) if dates_array.size > 1
            when 'geographic'
              next unless node.key? :content
              n = Nokogiri::XML::Node.new('mods:geographic', ng_xml)
              if node.key?(:uri) && node[:uri].present?
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
        return unless types.is_a? Hash

        valid_keys = [:collection, :content].all? { |s| types.key? s }
        return unless valid_keys

        xpath = '/mods:mods/mods:typeOfResource'
        ng_xml.search(xpath, { 'xmlns:mods' => MODS_NS }).each(&:remove)

        record = ng_xml.root

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
        return unless genres.is_a? Hash

        valid_keys = [:content, :authority].all? { |s| genres.key? s }
        return unless valid_keys

        xpath = '/mods:mods/mods:genre'
        ng_xml.search(xpath, { 'xmlns:mods' => MODS_NS }).each(&:remove)

        record = ng_xml.root

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
        xpath = '/mods:mods/mods:language'
        ng_xml.search(xpath, { 'xmlns:mods' => MODS_NS }).each(&:remove)

        record = ng_xml.root

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
        terms_hash = {}
        terms_hash[:title] = title

        # Creator, contributor and any name
        names_hash = { 'name' => [], 'type' => [], 'authority' => [] }
        names_xpath = '/mods:mods/mods:name'
        ng_xml.search(names_xpath, { 'xmlns:mods' => MODS_NS }).each do |node|
          part_node = node.at('./mods:namePart', { 'xmlns:mods' => MODS_NS })
          role_code = node.at('./mods:role/mods:roleTerm[@type="code"]', { 'xmlns:mods' => MODS_NS })
          next if part_node.nil? || role_code.nil?
          next if role_code.nil? || DRI::Vocabulary.marc_relators_creator.key?(role_code.content)

          names_hash['authority'] << (node['authority'] ? node['authority'] : '')
          names_hash['name'] << part_node.content
          names_hash['type'] << role_code.content.prepend('role_')
        end
        terms_hash[:roles] = names_hash

        terms_hash[:desc_abstract] = desc_abstract
        terms_hash[:desc_toc] = desc_toc
        terms_hash[:desc_note] = desc_note
        terms_hash[:desc_physdesc_note] = desc_physdesc_note
        terms_hash[:rights] = rights
        terms_hash[:language] = mods_language_text

        # Type
        type_hash = { collection: collection?, content: [] }
        type_xpath = '/mods:mods/mods:typeOfResource'
        ng_xml.search(type_xpath, { 'xmlns:mods' => MODS_NS }).each do |node|
          type_hash[:content] << node.content
        end
        terms_hash[:resource_type] = type_hash

        # Genre
        genre_hash = { authority: [], content: [] }
        genre_xpath = '/mods:mods/mods:genre'
        ng_xml.search(genre_xpath, { 'xmlns:mods' => MODS_NS }).each do |node|
          genre_hash[:content] << node.content
          genre_hash[:authority] << (node['authority'] ? node['authority'] : '')
        end

        terms_hash[:mods_genre] = genre_hash

        origin_metadata_array = []
        origin_info_nodes = ng_xml.search('/mods:mods/mods:originInfo', { 'xmlns:mods' => MODS_NS })

        origin_info_nodes.each do |origin|
          origin_info_hash = {}
          index = 0
          origin.children.select(&:element?).each do |elem|
            tag = elem.name

            case tag
            when 'place'
              place_hash = { tag: 'place', content: '' }
              p_term = elem.at('./mods:placeTerm', { 'xmlns:mods' => MODS_NS })
              place_hash[:content] = p_term.content
              origin_info_hash["#{index}"] = place_hash
              index += 1
            when 'issuance', 'publisher', 'edition', 'frequency'
              elem_hash = { tag: tag, content: elem.content }
              origin_info_hash["#{index}"] = elem_hash
              index += 1
            else
              # date
              date_hash = { tag: tag, start: '', end: '', encoding: '' }
              case elem['point']
              when 'start'
                date_hash[:start] << elem.content
                end_node = origin.children.select { |node| node.name == tag && node['point'] == 'end' }
                date_hash[:end] << end_node.first.content unless end_node.empty?
              when 'end'
                next
              else
                date_hash[:start] << elem.content
                date_hash[:end] << ''
              end
              date_hash[:encoding] << (elem['encoding'].nil? ? '' : elem['encoding'])

              origin_info_hash["#{index}"] = date_hash
              index += 1
            end
          end

          origin_metadata_array << origin_info_hash
        end
        terms_hash[:origin_metadata] = origin_metadata_array

        # Subjects: topic, name_coverage, temporal_coverage, geographical_coverage
        subjects_array = []
        subject_nodes = ng_xml.search('/mods:mods/mods:subject', { 'xmlns:mods' => MODS_NS })
        subject_nodes.each do |snode|
          subj_hash = { values: [], authority: '' }

          subj_hash[:authority] = snode[:authority] unless snode[:authority].nil?
          snode.children.select(&:element?).each do |node|
            tag = node.name

            case tag
            when 'topic'
              topic_hash = { tag: tag, content: node.content }
              subj_hash[:values] << topic_hash
            when 'name'
              name_hash = { tag: tag, display: '', role: '' }
              node_name = node.at('./mods:namePart', { 'xmlns:mods' => MODS_NS })

              next if node_name.nil?

              name_hash[:display] = node_name.content
              node_role = node.at('./mods:role/mods:roleTerm[@type="code"]', { 'xmlns:mods' => MODS_NS })
              name_hash[:role] = node_role.content unless node_role.nil?

              subj_hash[:values] << name_hash
            when 'temporal'
              temporal_hash = { tag: tag, start: '', end: '', encoding: '' }
              case node['point']
              when 'start'
                temporal_hash[:start] = node.content
                end_node = snode.children.select { |n| n['point'] == 'end' }
                temporal_hash[:end] = end_node.first.content unless end_node.empty?
              when 'end'
                next
              else
                temporal_hash[:start] = node.content
              end
              temporal_hash[:encoding] = node[:encoding] unless node[:encoding].nil?

              subj_hash[:values] << temporal_hash
            when 'geographic'
              geo_hash = { tag: tag, content: node.content }
              if node['authority'].present? && node['authority'] == 'logainm'
                geo_hash[:uri] = node['valueURI'] if node['valueURI'].present?
              end
              subj_hash[:values] << geo_hash
            else
              next
            end
          end # specific subject elements

          subjects_array << subj_hash
        end # all subjects
        terms_hash[:subject_metadata] = subjects_array

        terms_hash
      end

      # Looks all dates included in a given mods:originInfo element and determines whether
      # they are all iso8601 or w3cdtf encoded, and valid
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

        start_count == end_count && start_count <= 1 ? true : false
      end

      # Looks all dates included in all mods:originInfo elements and determines whether
      # they are all iso8601 or w3cdtf encoded, and valid
      # @return [Boolean] true if valid, encoded dates; false otherwise
      def validate_all_dates
        origin_nodes = ng_xml.search('//mods:originInfo', { 'xmlns:mods' => MODS_NS })

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
        errors = {}

        creator_result = false
        identifier_result = false
        uri_result = true
        ext_uri_result = true
        title_result = false
        description_result = false
        rights_result = false
        type_result = false
        date_result = false

        creator_result = true if creator.any? { |v| !v.blank? }

        unless creator_result == true
          marc_rels = *(DRI::Vocabulary.marc_relators.map { |s| s.prepend('role_').to_sym })

          marc_rels.each do |role|
            res = send(role).any? { |v| !v.blank? }
            creator_result = true if res
            break if res
          end
        end
        # This is the mods identifier used internally in DRI:
        # uniquely identify a record/relationships management
        identifier_result = true if mods_id_local.any? { |v| !v.blank? }
        identifier_uri.each { |value| uri_result = false unless !value.blank? && Utils.valid_uri?(value) }
        # Check that for external relationships terms, the specified URIs are valid
        related_items_digital.each do |value|
          ext_uri_result = false unless !value.blank? && Utils.valid_uri?(value)
        end
        title_result = true if title.any? { |v| !v.blank? }
        description_result = true if description.any? { |v| !v.blank? }
        rights_result = true if rights.any? { |v| !v.blank? }
        type_result = true if resource_type.any? { |v| !v.blank? }

        unless type_result == true
          type_result = true if mods_genre.any? { |v| !v.blank? }
        end

        # Creation date can either be: dateCreated, dateIssued,
        # dateCaptured (in this priority order)
        date_result = true if creation_date.any? { |v| !v.blank? }
        dates_array = [creation_date_start, published_date, issued_date_start, captured_date,
                       captured_date_start, other_date, other_date_start]
        unless date_result
          dates_array.each do |dates|
            res = dates.any? { |v| !v.blank? }
            date_result = true if res
            break if res
          end
        end

        errors[:mods_id_local] = 'not present.' unless identifier_result == true
        errors[:identifier_uri] = 'invalid URI present' unless uri_result == true
        errors[:related_items_digital] = 'invalid URI present' unless ext_uri_result == true
        errors[:title] = "can\'t be blank" if title_result == false
        errors[:type] = "can\'t be blank" if type_result == false

        # If this is a collection then validate:
        # return errors unless mods_type_collection.present?

        errors[:creator] = "can\'t be blank" if creator_result == false
        errors[:description] = "can\'t be blank" if description_result == false
        errors[:rights] = "can\'t be blank" if rights_result == false
        errors[:date] = "can\'t be blank" if date_result == false

        errors
      end # custom_validations

      load_inherited_terminology
    end # class
  end # module
end # module
