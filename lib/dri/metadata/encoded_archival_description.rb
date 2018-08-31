# DRI namespace
module DRI
  # Metadata namespace
  module Metadata
    # Implements the descMetadata datastream for DRI::EncodedArchivalDescription ROOT collection digital objects
    # extends from DRI::Metadata::Base
    class EncodedArchivalDescription < DRI::Datastreams::OmDatastream
      include DRI::Metadata
      extend DRI::Metadata::Terminologies::Ead

      # synchronize_metadata_on_save attribute getter
      # Flag used to indicate whether EAD component children creation should be triggered
      # when saving an EAD parent component
      # @see DRI::EncodedArchivalDescription#synchronize_if_changed
      # @return [Boolean] true if object support children metadata objects creation; false otherwise
      def synchronize_metadata_on_save
        @synchronize_metadata_on_save || true
      end

      # Returns an empty, default EAD finding aid XML template
      #
      # @return [Nokogiri::Document] the EAD XML document
      def self.xml_template
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.doc.create_internal_subset('ead', '+//ISBN 1-931666-00-8//DTD ead.dtd (Encoded Archival Description (EAD) Version 2002)//EN', '')
          xml.ead {
            xml.eadheader {
              xml.eadid(identifier: '', countrycode: 'IE', mainagencycode: '') # identifier
              xml.filedesc {
                xml.publicationstmt {
                  xml.date(normal: '') # published_date
                }
                xml.titlestmt {
                  xml.titleproper
                }
              }
            }
            xml.archdesc(level: 'fonds') { # ead_level
              xml.did {
                xml.unittitle # title
                xml.unitdate(datechar: 'creation') # creation_date
                xml.unitdate(datechar: 'coverage') # temporal_coverage
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
              xml.dsc
            }
          }
        end

        builder.doc
      end # xml_template

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

          unless sorted_title.blank?
            solr_doc.merge!(Solrizer.solr_name('title_sorted', :stored_sortable, type: :string) => [sorted_title])
          end
        end

        # Type
        solr_doc.merge!(Solrizer.solr_name('type', :stored_searchable) => resource_type)
        solr_doc.merge!(Solrizer.solr_name('type', :facetable) => resource_type)
        solr_doc.merge!(Solrizer.solr_name('type', :stored_searchable, type: :string) => 'Collection')

        # EAD has several "name" tags, so we merge them together into the SOLR document
        solr_doc.merge!(Solrizer.solr_name('person', :facetable) => person_array_for_index)
        solr_doc.merge!(Solrizer.solr_name('person', :stored_searchable, type: :text) => person_array_for_index | DRI::Metadata::Transformations.transform_name(person_array_for_index))

        # all_metadata - A SOLR index of all the text contained in the XML document
        all_metadata = ''
        ng_xml.xpath('//text()').each do |text_node|
          all_metadata += text_node.text
          all_metadata += ' '
        end
        solr_doc.merge!(Solrizer.solr_name('all_metadata', :stored_searchable, type: :text) => [all_metadata])

        solr_doc.merge!(Solrizer.solr_name('creator', :facetable) => creator_for_index)
        solr_doc.merge!(Solrizer.solr_name('creator', :stored_searchable, type: :text) => creator_for_index)

        # Subject: generic, name and place
        solr_doc.merge!(Solrizer.solr_name('subject', :stored_searchable) => subject_for_index)
        solr_doc.merge!(Solrizer.solr_name('subject', :facetable) => subject_for_index)

        solr_doc.merge!(Solrizer.solr_name('name_coverage', :stored_searchable) => subject_name_for_index)
        solr_doc.merge!(Solrizer.solr_name('name_coverage', :facetable) => subject_name_for_index)

        solr_doc.merge!(Solrizer.solr_name('geographical_coverage', :stored_searchable) => subject_place_for_index)
        solr_doc.merge!(Solrizer.solr_name('geographical_coverage', :facetable) => subject_place_for_index)

        # Publisher
        solr_doc.merge!(Solrizer.solr_name('publisher', :stored_searchable) => publisher) unless publisher == []

        # Indexing dates for display
        # Creation Date
        cdate_array = creation_date.collect.with_index do |value, idx|
          if creation_date(idx).normal_at.empty?
            DRI::Metadata::Transformations.create_dcmi_period(value)
          else
            iso_date = creation_date(idx).normal_at[0]
            iso_to_dcmi_period(value, iso_date)
          end
        end
        pdate_array = published_date.collect.with_index do |value, idx|
         if published_date(idx).normal_at.empty?
           DRI::Metadata::Transformations.create_dcmi_period(value)
         else
           iso_date = published_date(idx).normal_at[0]
           iso_to_dcmi_period(value, iso_date)
         end
        end
        solr_doc.merge!(Solrizer.solr_name('creation_date', :stored_searchable) => cdate_array) unless creation_date.empty?
        # Published Date
        solr_doc.merge!(Solrizer.solr_name('published_date', :stored_searchable) => pdate_array) unless published_date.empty?
        # Subject(Temporal)
        subject_temporal_array = subject_temporal_for_index
        solr_doc.merge!(Solrizer.solr_name('temporal_coverage', :stored_searchable) => subject_temporal_array)
        solr_doc.merge!(Solrizer.solr_name('temporal_coverage', :facetable) => subject_temporal_array)

        #solr_doc.merge!(Solrizer.solr_name('creation_date_idx', :stored_searchable) => creation_date_idx) unless creation_date_idx == []

        # Index date ranges, and iso dates into the appropriate solr fields
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

        # Indexing creation_date_idx is necessary for children, in case they inherit from the root collection
        solr_doc.merge!(Solrizer.solr_name('creation_date_idx', :stored_searchable) => creation_date_idx)

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

        uris = geocode_logainm.select { |i| i[/\A#{URI.regexp(['http', 'https'])}\z/] }
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
      end # solr_doc

      #
      # @return [String] the formatted date string in DCMI Period encoding
      def iso_to_dcmi_period(display, date)
        if date.include?('/')
          range = date.split('/')
          DRI::Metadata::Transformations.create_dcmi_period(display, range[0], range[1])
        else
          DRI::Metadata::Transformations.create_dcmi_period(display, date)
        end
      end

      # Returns all metadata related to people names for Solr indexing
      # People facet
      # @return [Array<String>] array of all people names metadata values for Solr indexing
      def person_array_for_index
        creator | pers_name | corp_name | name | fam_name
      end

      # Returns all metadata related to creator for Solr indexing
      # Including role information if present
      # @example Example of creator formatting with role
      #   <ead:persname role="creator">M. Walcott</ead:persname> is indexed as:
      #   "M. Walcott (Creator)"
      # @return [Array<String>] array of all creator metadata values, formatted to include role info, for Solr indexing
      def creator_for_index
        creators_array = []
        query = '/ead/archdesc/did/origination/*[not(@role="contributor")]'
        ng_xml.search(query).each { |n| creators_array << (n['role'].nil? ? n.content : "#{n.content} (#{n['role']})") }

        creators_array
      end

      # Returns all metadata related to subjects for Solr indexing
      # Mapping to UI Subjects: controlaccess/subject or subject
      # These are generic subjects similar to dc:coverage
      # @return [Array<String>] array of all subject metadata values for Solr indexing
      def subject_for_index
        subject | subject_archdesc | subject_anywhere | persname_subject | name_subject | corpname_subject | famname_subject | geogname_subject
      end

      # Returns all metadata related to name subjects for Solr indexing
      # These are DRI's Subject (Name) values
      # @return [Array<String>] array of all subject names metadata values for Solr indexing
      def subject_name_for_index
        persname_roles = pers_name_cvg.map.with_index { |n, idx| pers_name_cvg(idx).role.empty? ? n : (n + " (#{pers_name_cvg(idx).role[0]})") }
        name_roles = name_cvg.map.with_index { |n, idx| name_cvg(idx).role.empty? ? n : (n + " (#{name_cvg(idx).role[0]})") }
        corpname_roles = corp_name_cvg.map.with_index { |n, idx| corp_name_cvg(idx).role.empty? ? n : (n + " (#{corp_name_cvg(idx).role[0]})") }
        famname_roles = fam_name_cvg.map.with_index { |n, idx| fam_name_cvg(idx).role.empty? ? n : (n + " (#{fam_name_cvg(idx).role[0]})") }

        name_roles | persname_roles | corpname_roles | famname_roles
      end

      # Returns all metadata related to place/location subjects for Solr indexing
      # These are DRI Subject (Place) values
      # @return [Array<String>] array of all subject place metadata values for Solr indexing
      def subject_place_for_index
        geo_roles = geog_name_cvg.map.with_index { |n, idx| geog_name_cvg(idx).role.empty? ? n : (n + " (#{geog_name_cvg(idx).role[0]})") }

        geo_roles
      end

      # Returns all metadata related to temporal subjects for Solr indexing
      # These are DRI Subject (Temporal) values
      # @return [Array<String>] array of all subject temporal metadata values for Solr indexing
      def subject_temporal_for_index
        date_array = date_cvg.collect.with_index do |value, idx|
          if date_cvg(idx).normal_at.empty?
            DRI::Metadata::Transformations.create_dcmi_period(value)
          else
            iso_date = date_cvg(idx).normal_at[0]
            iso_to_dcmi_period(value, iso_date)
          end
        end

        temporal_array = temporal_coverage.collect.with_index do |value, idx|
          if temporal_coverage(idx).normal_at.empty?
            DRI::Metadata::Transformations.create_dcmi_period(value)
          else
            iso_date = temporal_coverage(idx).normal_at[0]
            iso_to_dcmi_period(value, iso_date)
          end
        end

        temporal_array | date_array
      end

      # Returns all date ranges formatted in ISO8601 for indexing
      # @note EAD date format: start/end [YYYYmmdd/YYYYmmdd | YYYY/YYYY]
      # @return [Hash] the hash with all the dates present in the metadata to be indexed as date ranges
      def date_ranges_for_index
        dates_hash = {}

        dates_hash['creation_date'] = creation_date_idx unless creation_date_idx.empty?
        dates_hash['published_date'] = published_date_idx unless published_date_idx.empty?
        dates_hash['subject_date'] = temporal_coverage_idx | date_idx unless temporal_coverage_idx.empty? && date_idx.empty?

        dates_hash
      end

      # Determine whether the metadata describes a collection
      def collection?
        # This a descMetadata class for EAD ROOT collections
        # Always true
        true
      end

      # Creates EAD scopecontent XML elements from an array of metadata values.
      # Used when updating metadata via attribute accessors
      # @see DRI::EncodedArchivalDescription#desc_scope_content=
      # @param [Array<String>] desc_array array of metadata values for scope content field
      def add_desc_scope_content(desc_array)
        ng_xml.search('/ead/archdesc/scopecontent').each(&:remove)

        archdesc_node = ng_xml.at('/ead/archdesc')
        sc = Nokogiri::XML::Node.new('scopecontent', ng_xml)
        desc_array.each do |desc|
          next if desc.empty?

          p = Nokogiri::XML::Node.new('p', ng_xml)
          p.content = desc
          sc.add_child(p)
        end
        archdesc_node.add_child(sc) unless sc.children.empty?
      end

      # Creates EAD abstract XML elements from an array of metadata values.
      # Used when updating metadata via attribute accessors
      # @see DRI::EncodedArchivalDescription#desc_abstract=
      # @param [Array<String>] desc_array array of metadata values for abstract field
      def add_desc_abstract(desc_array)
        ng_xml.search('/ead/archdesc/did/abstract').each(&:remove)

        did_node = ng_xml.at('/ead/archdesc/did')
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
        ng_xml.search('/ead/archdesc/bioghist').each(&:remove)

        archdesc_node = ng_xml.at('/ead/archdesc')
        bh = Nokogiri::XML::Node.new('bioghist', ng_xml)
        desc_array.each do |desc|
          next if desc.empty?

          p = Nokogiri::XML::Node.new('p', ng_xml)
          p.content = desc
          bh.add_child(p)
        end
        archdesc_node.add_child(bh) unless bh.children.empty?
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

        ng_xml.search('/ead/archdesc/did/unitdate[@datechar[contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "creation")]]').each(&:remove)

        did_node = ng_xml.at('/ead/archdesc/did')
        dates[:display].each_with_index do |disp, idx|
          next if disp.empty?

          node = Nokogiri::XML::Node.new('unitdate', ng_xml)
          node.content = disp
          node[:datechar] = 'creation'
          node[:normal] = dates[:normal][idx] unless dates[:normal][idx].empty?
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

        ng_xml.search('/ead/eadheader/filedesc/publicationstmt/date').each(&:remove)

        pub_stmt = ng_xml.at('/ead/eadheader/filedesc/publicationstmt')
        if pub_stmt.nil?
          file_desc = ng_xml.at('/ead/eadheader/filedesc')
          pub_stmt = Nokogiri::XML::Node.new('publicationstmt', ng_xml)
          file_desc.add_child(pub_stmt)
        end
        dates[:display].each_with_index do |disp, idx|
          next if disp.empty?

          node = Nokogiri::XML::Node.new('date', ng_xml)
          node.content = disp
          node[:normal] = dates[:normal][idx] unless dates[:normal][idx].empty?
          pub_stmt.add_child(node)
        end
      end

      # Creates EAD persname, name, corpname, famname XML elements from an array of metadata values
      # Updates every person element under origination (creators)
      # @see DRI::EncodedArchivalDescription#creator=
      # @example Sample Hash:
      #   { display: ['Creator 1', 'Creator no role'], role: ['institution', ''], tag: ['persname', 'name'] }
      # @param [Hash] creators the attributes and content required to create a persname
      # @option creators [Array<String>] :display the content for the node
      # @option creators [Array<String>] :role the role attribute for the node
      # @option creators [Array<String>] :tag the name of the person tag to add
      def add_creator(creators)
        return unless creators.is_a?(Hash)
        creators.symbolize_keys!
        valid_keys = [:tag, :display, :role].all? { |s| creators.key? s }
        return unless valid_keys && creators[:display].size == creators[:role].size && creators[:role].size == creators[:tag].size

        ng_xml.search('/ead/archdesc/did/origination/*[(local-name()="name" or local-name()="persname" or local-name()="famname" or local-name()="corpname") and not(@role="contributor")]').each(&:remove)

        origination = ng_xml.at('/ead/archdesc/did/origination')
        if origination.nil?
          did_node = ng_xml.at('/ead/archdesc/did')
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
        ng_xml.search('/ead/archdesc/did/origination/persname[@role="contributor"]').each(&:remove)

        origination = ng_xml.at('/ead/archdesc/did/origination')
        if origination.nil?
          did_node = ng_xml.at('/ead/archdesc/did')
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

        ng_xml.search('/ead/archdesc/controlaccess/*[(local-name()="name" or local-name()="persname" or local-name()="famname" or local-name()="corpname") and not(@role="subject")]').each(&:remove)

        control_a = ng_xml.at('/ead/archdesc/controlaccess')
        if control_a.nil?
          archdesc_node = ng_xml.at('/ead/archdesc')
          control_a = Nokogiri::XML::Node.new('controlaccess', ng_xml)
          archdesc_node.add_child(control_a)
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

        ng_xml.search('/ead/archdesc/did/unitdate[not(contains(@datechar, "creation"))]').each(&:remove)

        did_node = ng_xml.at('/ead/archdesc/did')

        dates[:display].each_with_index do |disp, idx|
          next if disp.empty?

          node = Nokogiri::XML::Node.new('unitdate', ng_xml)
          node.content = disp
          node[:datechar] = dates[:datechar][idx]
          node[:normal] = dates[:normal][idx] unless dates[:normal][idx].empty?
          did_node.add_child(node)
        end
      end

      # Creates EAD relatedmaterial XML elements from an array of metadata values.
      # Used when updating metadata via attribute accessors (Links to related materials)
      # @see DRI::EncodedArchivalDescription#related_material=
      # @param [Array<String>] materials array of metadata values for relatedmaterial field (relatedmaterial)
      def add_related_material(materials)
        links = materials.select{ |i| i[/\A#{URI.regexp(['http', 'https'])}\z/] }

        ng_xml.search('/ead/archdesc/relatedmaterial').each(&:remove)

        arch_desc = ng_xml.at('/ead/archdesc')
        # Add related materials that are not external links
        links.each do |link|
          next if  link.empty?

          node = Nokogiri::XML::Node.new('relatedmaterial', ng_xml)
          ext_ref = Nokogiri::XML::Node.new('extref', ng_xml)
          ext_ref['href'] = link
          node.add_child(ext_ref)
          arch_desc.add_child(node)
        end
      end

      # Creates EAD altformavail XML elements from an array of metadata values.
      # Used when updating metadata via attribute accessors (Alternative form available)
      # @see DRI::EncodedArchivalDescription#alternative_form=
      # @param [Array<String>] materials array of metadata values for persname field (altformavail)
      def add_alternative_form(materials)
        links = materials.select{ |i| i[/\A#{URI.regexp(['http', 'https'])}\z/] }

        ng_xml.search('/ead/archdesc/altformavail').each(&:remove)

        arch_desc = ng_xml.at('/ead/archdesc')
        links.each do |link|
          next if link.empty?

          node = Nokogiri::XML::Node.new('altformavail', ng_xml)
          p = Nokogiri::XML::Node.new('p', ng_xml)
          ext_ref = Nokogiri::XML::Node.new('extref', ng_xml)
          ext_ref['href'] = link
          p.add_child(ext_ref)
          node.add_child(p)
          arch_desc.add_child(node)
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

        ng_xml.search('/ead/archdesc/controlaccess/geogname[not(@role="subject")]').each(&:remove)

        control_a = ng_xml.at('/ead/archdesc/controlaccess')
        if control_a.nil?
          archdesc_node = ng_xml.at('/ead/archdesc')
          control_a = Nokogiri::XML::Node.new('controlaccess', ng_xml)
          archdesc_node.add_child(control_a)
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

      # Creates EAD langmaterial/language XML elements from a Hash of metadata values.
      # Updates every language element under langmaterial (language metadata)
      # @see DRI::EncodedArchivalDescription#language=
      # @example Sample Hash:
      #   { langcode: ['eng'], text: ['English'] }
      # @param [Hash] languages hash of language metadata values to set
      # @option languages [Array<String>] :langcode the iso639-2b code attribute values for the nodes
      # @option languages [Array<String>] :text the displayable language names for the nodes
      def add_language(languages)
        return unless languages.is_a?(Hash)

        languages.symbolize_keys!
        valid_keys = [:langcode, :text].all? { |s| languages.key? s }

        return unless valid_keys && languages[:langcode].size == languages[:text].size

        ng_xml.search('/ead/archdesc/did/langmaterial/language').each(&:remove)

        lang_mat = ng_xml.at('/ead/archdesc/did/langmaterial')
        if lang_mat.nil?
          did_node = ng_xml.at('/ead/archdesc/did')
          lang_mat = Nokogiri::XML::Node.new('langmaterial', ng_xml)
          did_node.add_child(lang_mat)
        end
        languages[:text].each_with_index do |lang, idx|
          next if lang.empty?

          node = Nokogiri::XML::Node.new('language', ng_xml)
          node.content = lang
          node[:langcode] = languages[:langcode][idx] unless languages[:langcode][idx].empty?
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
        ng_xml.search('/ead/archdesc/did/origination/*[(local-name()="name" or local-name()="persname" or local-name()="famname" or local-name()="corpname") and not(@role="contributor")]').each do |node|
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
        ng_xml.search('/ead/eadheader/filedesc/publicationstmt/date').each do |node|
          published_date_hash[:display] << node.content
          published_date_hash[:normal] << (node['normal'].nil? ? '' : node['normal'])
        end
        terms_hash[:published_date] = published_date_hash

        creation_date_hash = {}
        creation_date_hash[:display] = []
        creation_date_hash[:normal] = []
        ng_xml.search('/ead/archdesc/did/unitdate[@datechar[contains(translate(., "ABCDEFGHJIKLMNOPQRSTUVWXYZ", "abcdefghjiklmnopqrstuvwxyz"), "creation")]]').each do |node|
          creation_date_hash[:display] << node.content
          creation_date_hash[:normal] << (node['normal'].nil? ? '' : node['normal'])
        end
        terms_hash[:creation_date] = creation_date_hash

        name_coverage_hash = {}
        name_coverage_hash[:display] = []
        name_coverage_hash[:role] = []
        name_coverage_hash[:tag] = []
        ng_xml.search('/ead/archdesc/controlaccess/*[(local-name()="name" or local-name()="persname" or local-name()="famname" or local-name()="corpname") and not(@role="subject")]').each do |node|
          name_coverage_hash[:display] << node.content
          name_coverage_hash[:role] << (node['role'].nil? ? '' : node['role'])
          name_coverage_hash[:tag] << node.name
        end
        terms_hash[:name_coverage] = name_coverage_hash

        geogname_coverage_access_hash = {}
        geogname_coverage_access_hash[:display] = []
        geogname_coverage_access_hash[:type] = []
        ng_xml.search('/ead/archdesc/controlaccess/geogname[not(@role="subject")]').each do |node|
          geogname_coverage_access_hash[:display] << node.content
          if !node['source'].nil?
            geogname_coverage_access_hash[:type] << node['source']
          else
            geogname_coverage_access_hash[:type] << (node['rules'].nil? ? '' : node['rules'])
          end
        end
        terms_hash[:geogname_coverage_access] = geogname_coverage_access_hash

        temporal_coverage_hash = {}
        temporal_coverage_hash[:display] = []
        temporal_coverage_hash[:normal] = []
        temporal_coverage_hash[:datechar] = []
        ng_xml.search('/ead/archdesc/did/unitdate[not(contains(@datechar, "creation"))]').each do |node|
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

      # No parent to update as this object is a EAD ROOT Collection
      def update_parent_metadata(_parent, _full_metadata)
      end

      # Implement additional DRI metadata validations as this class does not inherit
      # from DRI::Metadata::Base
      # @return [Hash] the hash with any errors from validation
      def custom_validations
        errors = {}

        # Mandatory elements at collection-level
        # Mandatory elements at collection-level
        title_result = false
        creator_result = false
        description_result = false
        date_result = false
        rights_result = false

        # EAD-specific validation from best practices
        ead_id_result = false
        cc_result = false
        rc_result = false
        ead_level_result = false
        ead_level_other_result = false

        # Title
        title_result = true if title.any? { |v| !v.blank? }
        # Creator
        creator_result = true if creator.any? { |v| !v.blank? }
        # Description
        description_result = true if description.any? { |v| !v.blank? }
        # A date is required
        date_result = true if creation_date.any? { |v| !v.blank? }
        date_result = true if temporal_coverage.any? { |v| !v.blank? }
        # Rights
        rights_result = true if rights.any? { |v| !v.blank? }

        # EAD-specific
        if DRI::Vocabulary.ead_level_values.include?(ead_level.first)
          ead_level_result = true if ead_level.any? { |v| !v.blank? }
          ead_level_other_result = true if ead_level_other.any? { |v| !v.blank? }
        end

        # Identifier validation
        ead_id_result = true if identifier.any? { |v| !v.blank? }
        # Validation for eadid, @countrycode is a mandatory attribute
        # for eadid element
        cc_result = true if country_code.any? { |v| !v.blank? }
        # Validation for eadid, @mainagencycode (repository_code here)
        # is mandatory for eadid element
        rc_result = true if repository_code.any? { |v| !v.blank? }

        # DRI Compulsory elements
        errors[:title] = "can\'t be blank" if title_result == false
        errors[:creator] = "can\'t be blank" if creator_result == false
        errors[:description] = "can\'t be blank" if description_result == false
        errors[:date] = "can\'t be blank" if date_result == false
        errors[:rights] = "can\'t be blank" if rights_result == false

        # Specific EAD validation
        if ead_level.include?('otherlevel')
          errors[:ead_level_other] = "can\'t be blank" if ead_level_other_result == false
        else
          errors[:ead_level] = "can\'t be blank" if ead_level_result == false
        end

        # EADID validation
        # 1. eadid must be present
        # 1.1 the attribute mainagencycode is compulsory for eadid
        # 1.2 the attribute countrycode is compulsory for eadid
        if ead_id_result == false
          errors[:identifier] = "can\'t be blank"
        elsif cc_result == false || rc_result == false
          errors[:identifier] = 'invalid use'
          errors[:country_code] = "can\'t be blank" if cc_result == false
          errors[:repository_code] = "can\'t be blank" if rc_result == false
        end

        errors
      end # custom_validations

      load_inherited_terminology
    end # class
  end # module
end # module
