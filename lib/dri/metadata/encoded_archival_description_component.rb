module DRI
  module Metadata
    # Implements the descMetadata datastream for DRI::EncodedArchivalDescription digital objects
    # extends from DRI::Metadata::Base
    class EncodedArchivalDescriptionComponent < DRI::Datastreams::OmDatastream
      include DRI::Metadata
      extend DRI::Metadata::Terminologies::EadComponent

      # synchronize_metadata_on_save attribute getter
      # Flag used to indicate whether EAD component children creation should be triggered
      # when saving an EAD parent component
      # @see DRI::EncodedArchivalDescription#synchronize_if_changed
      # @return [Boolean] true if object support children metadata objects creation; false otherwise
      def synchronize_metadata_on_save
        @synchronize_metadata_on_save || true
      end

      # Returns an empty, default EAD component XML template
      #
      # @return [Nokogiri::Document] the EAD component XML document
      def self.xml_template
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.c(level: '') {
            xml.did {
              xml.unittitle # title
              xml.unitid(identifier: '', repositorycode: '', countrycode: 'IE') # identifier
              xml.unitdate(datechar: 'creation', normal: '') # creation_date
              xml.unitdate(datechar: 'publication', normal: '') # published_date
              xml.origination {
                xml.persname(role: 'creator')
                xml.persname(role: 'contributor')
              }
              xml.langmaterial {
                xml.language(langcode: 'en')
              }
              xml.physdesc {
                xml.genreform # type
              }
            }
            xml.scopecontent # description
            xml.userestrict # rights
            xml.controlaccess {
              xml.subject # subject
              xml.persname(role: 'subject')
              xml.geogname(role: 'subject')
            }
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

        solr_doc.merge!(Solrizer.solr_name('title', :stored_searchable, type: :string) => title)
        # Title
        # title_sorted - A SOLR index for sorting titles
        if title.length > 0
          sorted_title = DRI::Metadata::Transformations.transform_title_for_sort(title[0])
          solr_doc.merge!(Solrizer.solr_name('title_sorted', :stored_sortable, type: :string) => [sorted_title]) unless sorted_title.empty?
        end

        # Type
        type_array = type_for_index

        solr_doc.merge!(Solrizer.solr_name('type', :stored_searchable) => type_array)
        solr_doc.merge!(Solrizer.solr_name('type', :facetable) => type_array)

        # Person  - EAD has several "name" tags, so we merge them together into the SOLR document
        person_array = person_array_for_index

        solr_doc.merge!(Solrizer.solr_name('person', :facetable) => person_array)
        solr_doc.merge!(Solrizer.solr_name('person', :stored_searchable, type: :text) => person_array | DRI::Metadata::Transformations.transform_name(person_array))

        # Creator
        creator_array = creator_for_index

        solr_doc.merge!(Solrizer.solr_name('creator', :facetable) => creator_array)
        solr_doc.merge!(Solrizer.solr_name('creator', :stored_searchable, type: :text) => creator_array)

        # all_metadata - A SOLR index of all the text contained in the XML document
        all_metadata = ''
        ng_xml.xpath('//text()').each do |text_node|
          all_metadata += text_node.text
          all_metadata += ' '
        end
        solr_doc.merge!(Solrizer.solr_name('all_metadata', :stored_searchable, type: :text) => [all_metadata])

        # Rights
        rights_array = rights_for_index
        solr_doc.merge!(Solrizer.solr_name('rights', :stored_searchable, type: :string) => rights_array)

        # Subject: generic, name and place
        subject_array = subject_for_index

        solr_doc.merge!(Solrizer.solr_name('subject', :stored_searchable) => subject_array)
        solr_doc.merge!(Solrizer.solr_name('subject', :facetable) => subject_array)

        subject_name_array = subject_name_for_index
        subject_place_array = subject_place_for_index

        solr_doc.merge!(Solrizer.solr_name('name_coverage', :stored_searchable) => subject_name_array)
        solr_doc.merge!(Solrizer.solr_name('name_coverage', :facetable) => subject_name_array)

        solr_doc.merge!(Solrizer.solr_name('geographical_coverage', :stored_searchable) => subject_place_array)
        solr_doc.merge!(Solrizer.solr_name('geographical_coverage', :facetable) => filter_uris(subject_place_array))

        # Display of Creation Date
        creation_date_array = creation_date_for_index
        solr_doc.merge!(Solrizer.solr_name('creation_date', :stored_searchable) => creation_date_array) unless creation_date_array == []
        solr_doc = remove_null_values(solr_doc, 'creation_date') if solr_doc[Solrizer.solr_name('creation_date', :stored_searchable)].present?

        # Geographical Coverage
        solr_doc.merge!(Solrizer.solr_name('geographical_coverage', :stored_searchable) => geographical_coverage)

        # Indexing dates for display
        # Display of Subject(Temporal)
        subject_temporal_array = subject_temporal_for_index

        solr_doc.merge!(Solrizer.solr_name('temporal_coverage', :stored_searchable) => subject_temporal_array)
        solr_doc.merge!(Solrizer.solr_name('temporal_coverage', :facetable) => filter_uris(subject_temporal_array))

        # Creation_date_idx field is necessary for inheriting the date from the parent if not present
        if creation_date_idx.empty?
          solr_doc.merge!(Solrizer.solr_name('creation_date_idx', :stored_searchable) => parent_field('creation_date_idx'))
        else
          solr_doc.merge!(Solrizer.solr_name('creation_date_idx', :stored_searchable) => creation_date_idx)
        end

        # Published Date
        pdate_array = published_date.collect.with_index do |value, idx|
          if published_date(idx).normal_at.empty?
            DRI::Metadata::Transformations.create_dcmi_period(value)
          else
            iso_date = published_date(idx).normal_at[0]

            if iso_date.include?('/')
              range = iso_date.split('/')
              DRI::Metadata::Transformations.create_dcmi_period(value, range[0], range[1])
            else
              DRI::Metadata::Transformations.create_dcmi_period(value, iso_date)
            end
          end
        end

        solr_doc.merge!(Solrizer.solr_name('published_date', :stored_searchable) => pdate_array) unless published_date.empty?
        # Index date ranges
        date_ranges = date_ranges_for_index # ALL the date ranges

        # Creation date dateRange index
        cdate_ranges = date_ranges.select { |key, _value| ['creation_date'].include?(key) }
        cdate_index = DRI::Metadata::Transformations.transform_date_ranges(cdate_ranges)
        if cdate_index.present?
          solr_doc.merge!(DRI::Metadata::Transformations::CREATION_DATE_RANGE_SOLR_FIELD => cdate_index)
          cdate_years = DRI::Metadata::Transformations.date_range_years(cdate_index)
          solr_doc.merge!(DRI::Metadata::Transformations::CREATION_DATE_YEAR_SOLR_FIELD => cdate_years)
          solr_doc.merge!(DRI::Metadata::Transformations::CREATION_DATE_RANGE_START_SOLR_FIELD => cdate_years.min)
          solr_doc.merge!(DRI::Metadata::Transformations::CREATION_DATE_RANGE_END_SOLR_FIELD => cdate_years.max)
        end

        # Published date dateRange index
        pdate_ranges = date_ranges.select { |key, _value| ['published_date'].include?(key) }
        pdate_index = DRI::Metadata::Transformations.transform_date_ranges(pdate_ranges)
        if pdate_index.present?
          solr_doc.merge!(DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_SOLR_FIELD => pdate_index)
          pdate_years = DRI::Metadata::Transformations.date_range_years(pdate_index)
          solr_doc.merge!(DRI::Metadata::Transformations::PUBLISHED_DATE_YEAR_SOLR_FIELD => pdate_years)
          solr_doc.merge!(DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_START_SOLR_FIELD => pdate_years.min)
          solr_doc.merge!(DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_END_SOLR_FIELD => pdate_years.max)
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
        # Index dcterms Point and Box data into geospatial Solr field (location_rpt)
        geospatial_hash = DRI::Metadata::Transformations.transform_geospatial({ 'geographical_coverage' => geocode_point | geocode_box })

        uris = geocode_logainm.select { |i| i[/\A#{URI.regexp(['http', 'https'])}\z/] } | reconciliation_uris
        if uris.present?
          linked_data = DRI::Metadata::Transformations.transform_geospatial({ 'geographical_coverage' => uris })

          geospatial_hash[:coords].concat(linked_data[:coords])
          geospatial_hash[:name].concat(linked_data[:name])
          geospatial_hash[:json].concat(linked_data[:json])
        end

        solr_doc.merge!(DRI::Metadata::Transformations::GEOSPATIAL_SOLR_FIELD => geospatial_hash[:coords]) unless geospatial_hash[:coords].empty?
        solr_doc.merge!(Solrizer.solr_name(DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD, :stored_searchable) => geospatial_hash[:name]) unless geospatial_hash[:name].empty?
        solr_doc.merge!(Solrizer.solr_name(DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD, :facetable, type: :text) => geospatial_hash[:name]) unless geospatial_hash[:name].empty?
        solr_doc.merge!(Solrizer.solr_name('geojson', :stored_searchable, type: :symbol) => geospatial_hash[:json]) unless geospatial_hash[:json].empty?

        solr_doc
      end # to_solr

      # Returns all metadata related to people names for Solr indexing
      # People facet
      # @return [Array<String>] array of all people names metadata values for Solr indexing
      def person_array_for_index
        name_coverage | persname_coverage | corpname_coverage | famname_coverage | creator | contributor
      end

      # Mapping to c/userestrict (Rights in the UI)
      # If the component does not have this information it is then inherited from the immediate parent
      # and returned for its indexing as Rights
      def rights_for_index
        rights.empty? ? parent_field('rights') : rights
      end

      # Maps to unitdate/@datechar="Creation", if the component does not have this information, it is then
      # inherited from the immediate parent (similar to rights - userestrict)
      def creation_date_for_index
        return parent_field('creation_date') if creation_date.empty?

        cdate_array = creation_date.collect.with_index do |value, idx|
          if creation_date(idx).normal_at.empty?
            DRI::Metadata::Transformations.create_dcmi_period(value)
          else
            iso_date = creation_date(idx).normal_at[0]
             if (iso_date.include?('/'))
              range = iso_date.split('/')
              DRI::Metadata::Transformations.create_dcmi_period(value, range[0], range[1])
            else
              DRI::Metadata::Transformations.create_dcmi_period(value, iso_date)
            end
          end
        end

        cdate_array
      end

      # Returns all metadata related to creator for Solr indexing
      # @return [Array<String>] array of all creator metadata values, formatted to include role info, for Solr indexing
      def creator_for_index
        creator.empty? ? parent_field('creator') : creator_with_roles
      end

      # Returns all metadata related to creator for Solr indexing
      # Including role information if present
      # @example Example of creator formatting with role
      #   <ead:persname role="creator">M. Walcott</ead:persname> is indexed as:
      #   "M. Walcott (Creator)"
      # @return [Array<String>] array of all creator metadata values, formatted to include role info, for Solr indexing
      def creator_with_roles
        creators_array = []
        ng_xml.search('/*/did/origination/*[not(@role="contributor")]').each { |n| creators_array << (n['role'].nil? ? n.content : "#{n.content} (#{n['role']})") }

        creators_array
      end

      # Return the values of the metadata field inherited from the parent
      # @param [String] field_name the metadata field name
      # @return [Array<String>] the array of metadata field values from the parent
      def parent_field(field_name)
        return [] unless describable && describable.governing_collection

        doc = describable.governing_collection.to_solr
        parent_field = doc[Solrizer.solr_name(field_name, :stored_searchable, type: :string)]

        parent_field || []
      end

      # Returns all metadata related to subjects for Solr indexing
      # Mapping to UI Subjects: controlaccess/subject or subject
      # These are generic subjects similar to dc:coverage
      # @return [Array<String>] array of all subject metadata values for Solr indexing
      def subject_for_index
        subject | subject_anywhere | name_subject | persname_subject | corpname_subject | geogname_subject | famname_subject
      end

      # Returns all metadata related to name subjects for Solr indexing
      # These are DRI's Subject(Name) values
      # @return [Array<String>] array of all subject names metadata values for Solr indexing
      def subject_name_for_index
        persname_roles = pers_name_cvg.map.with_index { |n, idx| pers_name_cvg(idx).role.empty? ? n : (n + " (#{pers_name_cvg(idx).role[0]})") }
        name_roles = name_cvg.map.with_index { |n, idx| name_cvg(idx).role.empty? ? n : (n + " (#{name_cvg(idx).role[0]})") }
        corpname_roles = corp_name_cvg.map.with_index { |n, idx| corp_name_cvg(idx).role.empty? ? n : (n + " (#{corp_name_cvg(idx).role[0]})") }
        famname_roles = fam_name_cvg.map.with_index { |n, idx| fam_name_cvg(idx).role.empty? ? n : (n + " (#{fam_name_cvg(idx).role[0]})") }

        name_roles | persname_roles | corpname_roles | famname_roles
      end

      # Returns all metadata related to place/location subjects for Solr indexing
      # These are DRI Subject(Place) values
      # @return [Array<String>] array of all subject place metadata values for Solr indexing
      def subject_place_for_index
        geo_roles = geog_name_cvg.map.with_index { |n, idx| geog_name_cvg(idx).role.empty? ? n : (n + " (#{geog_name_cvg(idx).role[0]})") }

        geo_roles
      end

      # Returns all metadata related to temporal subjects for Solr indexing
      # These are DRI Subject(Temporal) values
      # @return [Array<String>] array of all subject temporal metadata values for Solr indexing
      def subject_temporal_for_index
        date_array = date.collect.with_index do |value, idx|
          if date(idx).normal_at.empty?
            DRI::Metadata::Transformations.create_dcmi_period(value)
          else
            iso_date = date(idx).normal_at[0]

            if iso_date.include?('/')
              range = iso_date.split('/')
              DRI::Metadata::Transformations.create_dcmi_period(value, range[0], range[1])
            else
              DRI::Metadata::Transformations.create_dcmi_period(value, iso_date)
            end
          end
        end

        temporal_array = temporal_coverage.collect.with_index do |value, idx|
          if temporal_coverage(idx).normal_at.empty?
            DRI::Metadata::Transformations.create_dcmi_period(value)
          else
            iso_date = temporal_coverage(idx).normal_at[0]

            if (iso_date.include?('/'))
              range = iso_date.split('/')
              DRI::Metadata::Transformations.create_dcmi_period(value, range[0], range[1])
            else
              DRI::Metadata::Transformations.create_dcmi_period(value, iso_date)
            end
          end
        end

        temporal_array | date_array
      end

      # Returns all date ranges formatted in ISO8601 for indexing
      # @note EAD date format: start/end [YYYYmmdd/YYYYmmdd | YYYY/YYYY]
      # @return [Hash] the hash with all the dates present in the metadata to be indexed as date ranges
      def date_ranges_for_index
        dates_hash = {}

        cdate_array = creation_date_idx.empty? ? parent_field('creation_date_idx') : creation_date_idx

        dates_hash['creation_date'] = cdate_array unless cdate_array.empty?
        dates_hash['published_date'] = published_date_idx unless published_date_idx.empty?
        dates_hash['subject_date'] = temporal_coverage_idx | date_idx unless temporal_coverage_idx.empty? && date_idx.empty?

        dates_hash
      end

      # Returns array of types for ead components
      # Stores first physdesc/genreform and the ead level last
      # @return [Array<String>] types for indexing
      def type_for_index
        # Remove 'otherlevel' from ead type
        level = ead_level - ['otherlevel']

        resource_type | level.map(&:capitalize) | ead_level_other.map(&:capitalize)
      end

      # Determine whether the metadata describes a collection
      # (specified in the EAD component metadata)
      def collection?
        # level value other than item means it is a collection
        # from (DRI crosswalk)
        ead_level == ['item'] ? false : true
      end

      # Creates EAD scopecontent XML elements from an array of metadata values.
      # Used when updating metadata via attribute accessors
      # @see DRI::EncodedArchivalDescription#desc_scope_content=
      # @param [Array<String>] desc_array array of metadata values for scope content field
      def add_desc_scope_content(desc_array)
        ng_xml.search('/*/scopecontent').each(&:remove)

        comp = ng_xml.root
        sc = Nokogiri::XML::Node.new('scopecontent', ng_xml)
        desc_array.each do |desc|
          next if desc.empty?

          p = Nokogiri::XML::Node.new('p', ng_xml)
          p.content = desc
          sc.add_child(p)
        end
        comp.add_child(sc) unless sc.children.empty?
      end

      # Creates EAD abstract XML elements from an array of metadata values.
      # Used when updating metadata via attribute accessors
      # @see DRI::EncodedArchivalDescription#desc_abstract=
      # @param [Array<String>] desc_array array of metadata values for abstract field
      def add_desc_abstract(desc_array)
        ng_xml.search('/*/did/abstract').each(&:remove)

        did_node = ng_xml.at('/*/did')
        desc_array.each do |desc|
          next if desc.empty?

          abstract = Nokogiri::XML::Node.new('abstract', ng_xml)
          abstract.content = desc
          did_node.add_child(abstract)
        end
      end

      # Creates EAD bioghist XML elements from an array of metadata values.
      # Used when updating metadata via attribute accessors
      # @see DRI::EncodedArchivalDescription#desc_biog_hist=
      # @param [Array<String>] desc_array array of metadata values for biographical history field
      def add_desc_biog_hist(desc_array)
        ng_xml.search('/*/bioghist').each(&:remove)

        comp = ng_xml.root
        bh = Nokogiri::XML::Node.new('bioghist', ng_xml)
        desc_array.each do |desc|
          next if desc.empty?

          p = Nokogiri::XML::Node.new('p', ng_xml)
          p.content = desc
          bh.add_child(p)
        end
        comp.add_child(bh) unless bh.children.empty?
      end

      # Creates EAD unitdate XML elements from an array of metadata values.
      # Used when updating metadata via attribute accessors (creation date)
      # @see DRI::EncodedArchivalDescription#creation_date=
      # @example Sample Hash:
      #   { display: ['2015'], normal: ['20150101'] }
      # @param [Hash] dates hash of creation date metadata values to set
      # @option dates [Array<String>] :display array of metadata values for date display
      # @option dates [Array<String>] :normal array of metadata values encoded in iso8601 for index
      def add_creation_date(dates)
        return unless dates.is_a?(Hash)
        dates.symbolize_keys!
        valid_keys = [:display, :normal].all? { |s| dates.key? s }
        return unless valid_keys && dates[:display].size == dates[:normal].size

        ng_xml.search('/*/did/unitdate[@datechar[contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "creation")]]').each(&:remove)

        did_node = ng_xml.at('/*/did')
        dates[:display].each_with_index do |disp, idx|
          next if disp.empty?

          node = Nokogiri::XML::Node.new('unitdate', ng_xml)
          node.content = disp
          node['datechar'] = 'creation'
          node['normal'] = dates[:normal][idx] unless dates[:normal][idx].empty?
          did_node.add_child(node)
        end
      end

      # Creates EAD unitdate XML elements from an array of metadata values.
      # Used when updating metadata via attribute accessors (published date)
      # @see DRI::EncodedArchivalDescription#published_date=
      # @example Sample Hash:
      #   { display: ['2015'], normal: ['20150101'] }
      # @param [Hash] dates hash of creation date metadata values to set
      # @option dates [Array<String>] :display array of metadata values for date display
      # @option dates [Array<String>] :normal array of metadata values encoded in iso8601 for index
      def add_published_date(dates)
        return unless dates.is_a?(Hash)
        dates.symbolize_keys!
        valid_keys = [:display, :normal].all? { |s| dates.key? s }
        return unless valid_keys && dates[:display].size == dates[:normal].size

        ng_xml.search('/*/did/unitdate[@datechar="publication"]').each(&:remove)

        did_node = ng_xml.at('/*/did')
        dates[:display].each_with_index do |disp, idx|
          next if disp.empty?

          node = Nokogiri::XML::Node.new('unitdate', ng_xml)
          node.content = disp
          node['datechar'] = 'publication'
          node['normal'] = dates[:normal][idx] unless dates[:normal][idx].empty?
          did_node.add_child(node)
        end
      end

      # Creates EAD persname, name, corpname, famname XML elements from an array of metadata values
      # Updates every person element under origination (creators)
      # @see DRI::EncodedArchivalDescription#creator=
      # @example Sample Hash:
      #   { display: ['Creator 1', 'Creator no role'], role: ['institution', ''], tag: ['persname', 'name'] }
      # @param creators [Hash] the attributes and content required to create a persname
      # @option creators [Array<String>] :display the content for the node
      # @option creators [Array<String>] :role the role attribute for the node
      # @option creators [Array<String>] :tag the name of the person tag to add
      def add_creator(creators)
        return unless creators.is_a?(Hash)
        creators.symbolize_keys!
        valid_keys = [:tag, :display, :role].all? { |s| creators.key? s }
        return unless valid_keys && creators[:display].size == creators[:role].size && creators[:role].size == creators[:tag].size

        ng_xml.search('/*/did/origination/*[(local-name()="name" or local-name()="persname" or local-name()="famname" or local-name()="corpname") and not(@role="contributor")]').each(&:remove)

        origination = ng_xml.at('/*/did/origination')
        if origination.nil?
          did_node = ng_xml.at('/*/did')
          origination = Nokogiri::XML::Node.new('origination', ng_xml)
          did_node.add_child(origination)
        end
        creators[:display].each_with_index do |disp, idx|
          next unless DRI::Vocabulary.ead_people_tags.include?(creators[:tag][idx])
          next if disp.empty?

          node = Nokogiri::XML::Node.new(creators[:tag][idx], ng_xml)
          node.content = disp
          node[:role] = creators[:role][idx] unless creators[:role][idx].empty?
          origination.add_child(node)
        end
      end

      # Creates EAD persname XML elements from an array of metadata values.
      # Used when updating metadata via attribute accessors (contributor)
      # @see DRI::EncodedArchivalDescription#contributor=
      # @param [Array<String>] contributors array of metadata values for persname field (role contributor)
      def add_contributor(contributors)
        ng_xml.search('/*/did/origination/persname[@role="contributor"]').each(&:remove)

        origination = ng_xml.at('/*/did/origination')
        if origination.nil?
          did_node = ng_xml.at('/*/did')
          origination = Nokogiri::XML::Node.new('origination', ng_xml)
          did_node.add_child(origination)
        end
        contributors.each do |disp|
          next if disp.empty?

          node = Nokogiri::XML::Node.new('persname', ng_xml)
          node.content = disp
          node[:role] = 'contributor'
          origination.add_child(node)
        end
      end

      # Creates EAD persname, name, corpname or famname XML elements from an array of metadata values.
      # Updates every person element under controlaccess (name coverage metadata)
      # @see DRI::EncodedArchivalDescription#name_coverage=
      # @example Sample Hash:
      #   { display: ['Designer 1', 'Photographer 1'], role: ['designer', 'photographer'], tag: ['persname', 'corpname'] }
      # @param people [Hash] the attributes and content required to create a persname
      # @option :display [Array<String>] the content for the node
      # @option :role [Array<String>] the role attribute for the node
      # @option :tag [Array<String>] the name of the person tag to add
      def add_name_coverage(people)
        return unless people.is_a?(Hash)
        people.symbolize_keys!
        valid_keys = [:tag, :display, :role].all? { |s| people.key? s }
        return unless valid_keys && people[:display].size == people[:role].size && people[:role].size == people[:tag].size

        ng_xml.search('/*/controlaccess/*[(local-name()="name" or local-name()="persname" or local-name()="famname" or local-name()="corpname") and not(@role="subject")]').each(&:remove)

        control_a = ng_xml.at('/*/controlaccess')
        if control_a.nil?
          c_node = ng_xml.root
          control_a = Nokogiri::XML::Node.new('controlaccess', ng_xml)
          c_node.add_child(control_a)
        end
        people[:display].each_with_index do |disp, idx|
          next unless DRI::Vocabulary.ead_people_tags.include?(people[:tag][idx])
          next if disp.empty?

          node = Nokogiri::XML::Node.new(people[:tag][idx], ng_xml)
          node.content = disp
          node[:role] = people[:role][idx] unless people[:role][idx].empty?
          control_a.add_child(node)
        end
      end

      # Creates EAD unitdate XML elements from an array of metadata values.
      # Updates every unitdate element under archdesc/did (temporal coverage metadata)
      # @see DRI::EncodedArchivalDescription#temporal_coverage=
      # @example Sample Hash:
      #   { normal: ['2005'], datechar: ['coverage'], display: ['c. 2005'] }
      # @param [Hash] dates hash of creation date metadata values to set
      # @option dates [Array<String>] :display array of metadata values for date display
      # @option dates [Array<String>] :normal array of metadata values encoded in iso8601 for index
      # @option dates [Array<String>] :datechar array of metadata values for the datechar EAD attribute (type of date)
      def add_temporal_coverage(dates)
        return unless dates.is_a?(Hash)
        dates.symbolize_keys!
        valid_keys = [:display, :normal, :datechar].all? { |s| dates.key? s }
        return unless valid_keys && dates[:display].size == dates[:normal].size && dates[:normal].size == dates[:datechar].size

        ng_xml.search('/*/did/unitdate[not(@datechar="creation") and not(@datechar="publication")]').each(&:remove)

        did_node = ng_xml.at('/*/did')
        dates[:display].each_with_index do |disp, idx|
          next if disp.empty?

          node = Nokogiri::XML::Node.new('unitdate', ng_xml)
          node.content = disp
          node['datechar'] = dates[:datechar][idx]
          node['normal'] = dates[:normal][idx] unless dates[:normal][idx].empty?
          did_node.add_child(node)
        end
      end

      # Creates EAD relatedmaterial XML elements from an array of metadata values.
      # Used when updating metadata via attribute accessors (Links to related materials)
      # @see DRI::EncodedArchivalDescription#related_material=
      # @param [Array<String>] materials array of metadata values for relatedmaterial field (relatedmaterial)
      def add_related_material(materials)
        links = materials.select { |i| i[/\A#{URI.regexp(['http', 'https'])}\z/] }

        ng_xml.search('/*/relatedmaterial').each(&:remove)

        c_node = ng_xml.root
        # Add related materials that are not external links
        links.each do |link|
          next if link.empty?

          node = Nokogiri::XML::Node.new('relatedmaterial', ng_xml)
          ext_ref = Nokogiri::XML::Node.new('extref', ng_xml)
          ext_ref['href'] = link
          node.add_child(ext_ref)
          c_node.add_child(node)
        end
      end

      # Creates EAD altformavail XML elements from an array of metadata values.
      # Used when updating metadata via attribute accessors (Alternative form available)
      # @see DRI::EncodedArchivalDescription#alternative_form=
      # @param [Array<String>] materials array of metadata values for persname field (altformavail)
      def add_alternative_form(materials)
        links = materials.select { |i| i[/\A#{URI.regexp(['http', 'https'])}\z/] }

        ng_xml.search('/*/altformavail').each(&:remove)

        c_node = ng_xml.root
        links.each do |link|
          next if link.empty?

          node = Nokogiri::XML::Node.new('altformavail', ng_xml)
          p = Nokogiri::XML::Node.new('p', ng_xml)
          ext_ref = Nokogiri::XML::Node.new('extref', ng_xml)
          ext_ref['href'] = link
          p.add_child(ext_ref)
          node.add_child(p)
          c_node.add_child(node)
        end
      end

      # Creates EAD geogname XML elements from an array of metadata values.
      # Updates every geogname element under controlaccess (geographical coverage metadata)
      # @see DRI::EncodedArchivalDescription#geogname_coverage_access=
      # @example Sample Hash:
      #   { type: ['', 'dcterms:Point', 'logainm'], display: ['Dublin', 'name=Dublin; east=-6.266155; north=53.350140;', 'http://example.org/1234'] }
      # @param [Hash] locations hash of geogname metadata values to set
      # @option locations [Array<String>] :display array of metadata values for date display
      # @option locations [Array<String>] :type array of metadata values specifying the type of geocode (logainm, DCMI:Point or DCMI:Box, empty for free-text)
      def add_geogname_coverage_access(locations)
        return unless locations.is_a?(Hash)
        locations.symbolize_keys!
        valid_keys = [:type, :display].all? { |s| locations.key? s }
        return unless valid_keys && locations[:type].size == locations[:display].size

        ng_xml.search('/*/controlaccess/geogname[not(@role="subject")]').each(&:remove)

        control_a = ng_xml.at('/*/controlaccess')
        if control_a.nil?
          c_node = ng_xml.root
          control_a = Nokogiri::XML::Node.new('controlaccess', ng_xml)
          c_node.add_child(control_a)
        end
        locations[:display].each_with_index do |loc, idx|
          next if loc.empty?
          node = Nokogiri::XML::Node.new('geogname', ng_xml)
          node.content = loc
          unless locations[:type][idx].empty?
            case locations[:type][idx]
            when 'dcterms:Point'
              node['rules'] = 'dcterms:Point'
            when 'dcterms:Box'
              node['rules'] = 'dcterms:Box'
            when 'logainm'
              node['source'] = 'logainm'
            end
          end
          control_a.add_child(node)
        end
      end

      # Creates EAD langmaterial/language XML elements from an array of metadata values.
      # Updates every language element under langmaterial (language metadata)
      # @see DRI::EncodedArchivalDescription#language=
      # @example Sample Hash:
      #   { langcode: ['eng'], text: ['English'] }
      # @param [Hash] languages hash of geogname metadata values to set
      # @option languages [Array<String>] :langcode the iso639-2b code attribute values for the nodes
      # @option languages [Array<String>] :text the displayable language names for the nodes
      def add_language(languages)
        return unless languages.is_a?(Hash)

        languages.symbolize_keys!
        valid_keys = [:langcode, :text].all? { |s| languages.key? s }

        return unless valid_keys && languages[:langcode].size == languages[:text].size

        ng_xml.search('/*/did/langmaterial/language').each(&:remove)

        lang_mat = ng_xml.at('/*/did/langmaterial')
        if lang_mat.nil?
          did_node = ng_xml.at('/*/did')
          lang_mat = Nokogiri::XML::Node.new('langmaterial', ng_xml)
          did_node.add_child(lang_mat)
        end
        languages[:text].each_with_index do |lang, idx|
          next if lang.empty?

          node = Nokogiri::XML::Node.new('language', ng_xml)
          node.content = lang
          node['langcode'] = languages[:langcode][idx] unless languages[:langcode][idx].empty?
          lang_mat.add_child(node)
        end
      end

      # Returns a Hash with all the values for the DRI editable metadata fields
      # to be populated in a UI Edit form
      # @see DRI::EncodedArchivalDescription#retrieve_hash_attributes
      # @example Sample return hash:
      #   {
      #     title: ['The test title'],
      #     creator: { display: ['Creator 1', 'Creator no role'], role: ['institution', ''], tag: ['persname', 'name'] },
      #     contributor: ['Contributor 1'],
      #     desc_scope_content: ['This is a test description for the object.'],
      #     desc_abstract: ['This is a test abstract for the object.'],
      #     desc_biog_hist: ['This is a test biographical history for the object.'],
      #     rights: ['This is a statement about the rights associated with this object'],
      #     type: ['Collection'],
      #     published_date: { display: ['2015'], normal: ['20150101'] },
      #     creation_date: { display: ['2000-2010'], normal: ['20000101/20101231'] },
      #     name_coverage: { display: ['Designer 1', 'Photographer 1'], role: ['designer', 'photographer'], tag: ['persname', 'corpname'] },
      #     geogname_coverage_access: { type: ['', 'dcterms:Point', 'logainm'], display: ['Dublin', 'name=Dublin; east=-6.266155; north=53.350140;', 'http://example.org/1234'] },
      #     temporal_coverage: { normal: ['2005'], datechar: ['coverage'], display: ['c. 2005'] },
      #     subject: ['Ireland', 'something else'],
      #     name_subject: ['subject name'],
      #     persname_subject: ['subject persname'],
      #     corpname_subject: ['subject corpname'],
      #     geogname_subject: ['subject geogname'],
      #     famname_subject: ['subject famname'],
      #     publisher: ['Publisher 1'],
      #     related_material: ['http://example.org/relmat'],
      #     alternative_form: ['http://example.org/altform'],
      #     language: { langcode: ['eng'], text: ['English'] },
      #     format: ['395 files']
      #   }
      # @return [Hash] Hash of DRI EAD metadata
      def retrieve_terms_hash
        terms_hash = {}
        terms_hash[:title] = title

        # Creator
        creator_hash = {}
        creator_hash[:display] = []
        creator_hash[:role] = []
        creator_hash[:tag] = []
        ng_xml.search('/*/did/origination/*[(local-name()="name" or local-name()="persname" or local-name()="famname" or local-name()="corpname") and not(@role="contributor")]').each do |node|
          creator_hash[:display] << node.content
          creator_hash[:role] << (node['role'].nil? ? '' : node['role'])
          creator_hash[:tag] << node.name
        end
        terms_hash[:creator] = creator_hash

        terms_hash[:contributor] = contributor
        terms_hash[:publisher] = publisher
        terms_hash[:desc_scope_content] = desc_scope_content
        terms_hash[:desc_abstract] = desc_abstract
        terms_hash[:desc_biog_hist] = desc_biog_hist
        terms_hash[:desc_scope_content] = desc_scope_content
        terms_hash[:rights] = rights
        terms_hash[:type] = resource_type

        published_date_hash = {}
        published_date_hash[:display] = []
        published_date_hash[:normal] = []
        ng_xml.search('/*/did/unitdate[@datechar="publication"]').each do |node|
          published_date_hash[:display] << node.content
          published_date_hash[:normal] << (node['normal'].nil? ? '' : node['normal'])
        end
        terms_hash[:published_date] = published_date_hash

        creation_date_hash = {}
        creation_date_hash[:display] = []
        creation_date_hash[:normal] = []
        ng_xml.search('/*/did/unitdate[@datechar[contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "creation")]]').each do |node|
          creation_date_hash[:display] << node.content
          creation_date_hash[:normal] << (node['normal'].nil? ? '' : node['normal'])
        end
        terms_hash[:creation_date] = creation_date_hash

        name_coverage_hash = {}
        name_coverage_hash[:display] = []
        name_coverage_hash[:role] = []
        name_coverage_hash[:tag] = []
        ng_xml.search('/*/controlaccess/*[(local-name()="name" or local-name()="persname" or local-name()="famname" or local-name()="corpname") and not(@role="subject")]').each do |node|
          name_coverage_hash[:display] << node.content
          name_coverage_hash[:role] << (node['role'].nil? ? '' : node['role'])
          name_coverage_hash[:tag] << node.name
        end
        terms_hash[:name_coverage] = name_coverage_hash

        geogname_coverage_access_hash = {}
        geogname_coverage_access_hash[:display] = []
        geogname_coverage_access_hash[:type] = []
        ng_xml.search('/*/controlaccess/geogname[not(@role="subject")]').each do |node|
          geogname_coverage_access_hash[:display] << node.content
          if node['source'].nil?
            geogname_coverage_access_hash[:type] << (node['rules'].nil? ? '' : node['rules'])
          else
            geogname_coverage_access_hash[:type] << node['source']
          end
        end
        terms_hash[:geogname_coverage_access] = geogname_coverage_access_hash

        temporal_coverage_hash = {}
        temporal_coverage_hash[:display] = []
        temporal_coverage_hash[:normal] = []
        temporal_coverage_hash[:datechar] = []

        ng_xml.search('/*/did/unitdate[not(@datechar="creation") and not(@datechar="publication")]').each do |node|
          temporal_coverage_hash[:display] << node.content
          temporal_coverage_hash[:normal] << (node['normal'].nil? ? '' : node['normal'])
          temporal_coverage_hash[:datechar] << (node['datechar'].nil? ? '' : node['datechar'])
        end
        terms_hash[:temporal_coverage] = temporal_coverage_hash

        terms_hash[:subject] = subject
        terms_hash[:name_subject] = name_subject
        terms_hash[:persname_subject] = persname_subject
        terms_hash[:corpname_subject] = corpname_subject
        terms_hash[:famname_subject] = famname_subject
        terms_hash[:geogname_subject] = geogname_subject

        terms_hash[:related_material] = related_material
        terms_hash[:alternative_form] = alternative_form
        terms_hash[:format] = self.format

        language_hash = {}
        language_hash[:text] = []
        language_hash[:langcode] = []
        language.each_with_index do |value, idx|
          language_hash[:text] << value
          language_hash[:langcode] << (language(idx).langcode_at.empty? ? '' : language(idx).langcode_at[0])
        end

        terms_hash[:language] = language_hash

        terms_hash
      end

      # Updates an object's parent fullMetadata ds if the object's fullMetadata differs from the parent's
      # @param [DRI::EncodedArchivalDescription] parent the parent object for which to update fullMetadata ds
      # @param [DRI::Metadata::FullMetadata] full_metadata the child component's fullMetadata ds
      def update_parent_metadata(parent, full_metadata)
        return if parent.nil? # Return if we have no parent to sync with

        parent_md_xml = parent.fullMetadata.ng_xml.clone
        if parent_md_xml.collect_namespaces['xmlns:ead'] == 'urn:isbn:1-931666-22-9'
          # if original XML file uses EAD XSD and includes namespace prefixes, use them in the query
          query = "//*[ead:did/ead:unitid[@repositorycode='#{repository_code.first}' and @countrycode='#{country_code.first}' and text()='#{identifier.first}']]"
        else
          query = "//*[did/unitid[@repositorycode='#{repository_code.first}' and @countrycode='#{country_code.first}' and text()='#{identifier.first}']]"
        end
        # Find updated component to sync in parent's fullMetadata
        component_node = parent_md_xml.at(query)

        # Remove non-significant white space text nodes before comparing content
        child_xml = Nokogiri::XML.parse(full_metadata.ng_xml.to_s, &:noblanks)
        parent_xml = Nokogiri::XML.parse(component_node.to_s, &:noblanks)

        if parent_md_xml.collect_namespaces['xmlns:ead'] == 'urn:isbn:1-931666-22-9'
          # if parent metadata uses EAD XSD, need to add the ns prefixes and declarations
          # to the updated component xml as descMetadata removes all prefixes, namespaces
          child_xml.root.add_namespace('ead', 'urn:isbn:1-931666-22-9')
          child_xml.root.add_namespace('xlink', 'http://www.w3.org/1999/xlink')

          child_xml.search('//*').each do |n|
            # all ns prefix from root node to every child in the XML
            n.namespace = child_xml.root.namespace_definitions.find { |ns| ns.prefix == 'ead' }
            if n['href'] # dao @href attr is under xlink ns if using EAD XSD
              n.attribute('href').namespace = child_xml.root.namespace_definitions.find { |ns| ns.prefix == 'xlink' }
            end
          end

          # Need to remove the added ns declarations to the component before comparing
          child_xml_str = child_xml.root.serialize(save_with:0).gsub("\n", '').gsub('xmlns:ead="urn:isbn:1-931666-22-9" xmlns:xlink="http://www.w3.org/1999/xlink" ', '')

          same_metadata = (child_xml_str == parent_xml.root.serialize(save_with:0).gsub("\n", ''))
        else
          same_metadata = child_xml.root.serialize(save_with:0).gsub("\n", '') == parent_xml.root.serialize(save_with:0).gsub("\n", '')
        end

        # Check if the component node in parent XML is different
        unless component_node.nil? || same_metadata
          component_node.children.remove
          full_metadata.ng_xml.search('/*/*').each { |node| component_node.add_child(node.clone) }
          parent.fullMetadata.ng_xml = parent_md_xml
          # Prevent parent from automatically syncing
          if parent.fullMetadata.changed?
            parent.fullMetadata.ng_xml = parent_md_xml
            parent.trigger_update = false
            parent.trigger_ingest = false
            parent.save

            # Queue synchronization between parent and grandparent
            if parent.descMetadata.is_a?(DRI::Metadata::EncodedArchivalDescriptionComponent)
              DRI.queue.push(UpdateParentMetadataJob.new(parent.id))
            end
          end

          return true
        end

        if component_node.nil?
          Rails.logger.error("update_parent_metadata for #{parent.id}: Couldn't find component XML in parent's fullMetadata")
          "update_parent_metadata for #{parent.id}: Couldn't find component XML in parent's fullMetadata"
        else
          Rails.logger.info("update_parent_metadata for #{parent.id}: No differences in fullMetadata")
          "update_parent_metadata for #{parent.id}: No differences in fullMetadata"
        end
      end # update_parent_metadata

      # Implement additional DRI metadata validations
      # @return [Hash] the hash with any errors from validation
      def custom_validations
        errors = {}

        # DRI Mandatory elements (At collection-level)
        title_result = false

        # EAD-specific validation from best practices
        unit_id_result = false
        cc_result = false
        rc_result = false
        ead_level_result = false
        ead_level_other_result = false

        # Title
        title_result = true if title.any? { |v| !v.blank? }

        # EAD-specific
        if DRI::Vocabulary.ead_level_values.include?(ead_level.first)
          ead_level_result = true if ead_level.any? { |v| !v.blank? }
          ead_level_other_result = true if ead_level_other.any? { |v| !v.blank? }
        end

        # For validation of unitid or eadid we now use identifier
        # For EAD header maps to eadid and for components maps to unitid
        first_id = identifier[0]
        first_cc = country_code[0]
        first_rc = repository_code[0]
        # Handle the case where multiple unitid are present: only the first should carry the attributes
        unit_id_result = true unless first_id.blank?
        cc_result = true unless first_cc.blank?
        rc_result = true unless first_rc.blank?

        # DRI
        errors[:title] = "can't be blank" if title_result == false

        # Specific EAD validation
        if ead_level.include?('otherlevel')
          errors[:ead_level_other] = "can't be blank" if ead_level_other_result == false
        else
          errors[:ead_level] = "can't be blank" if ead_level_result == false
        end

        # UNITID validation
        # 1. unitid must be present
        # 1.1 the attribute mainagencycode is recommended for unitid
        # 1.2 the attribute countrycode is recommended for unitid
        if unit_id_result == false
          errors[:identifier] = "can't be blank"
        elsif cc_result == false || rc_result == false
          errors[:identifier] = 'invalid use'
          errors[:country_code] = "can't be blank" if cc_result == false
          errors[:repository_code] = "can't be blank" if rc_result == false
        end

        errors
      end # custom_validations

      load_inherited_terminology
    end # class
  end # module
end # module
