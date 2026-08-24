module DRI
  module Metadata
    # Implements the descMetadata datastream for DRI::EncodedArchivalDescription ROOT collection digital objects
    # extends from DRI::Metadata::Base
    class EncodedArchivalDescription < DRI::Datastreams::OmDatastream
      include DRI::Metadata
      include DRI::Metadata::CommonIndexing
      include DRI::Metadata::EadDateIndexing
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
          xml.ead do
            xml.eadheader do
              xml.eadid(identifier: '', countrycode: 'IE', mainagencycode: '') # identifier
              xml.filedesc do
                xml.publicationstmt do
                  xml.date(normal: '') # published_date
                end
                xml.titlestmt do
                  xml.titleproper
                end
              end
            end
            xml.archdesc(level: 'fonds') do # ead_level
              xml.did do
                xml.unittitle # title
                xml.unitdate(datechar: 'creation') # creation_date
                xml.unitdate(datechar: 'coverage') # temporal_coverage
                xml.origination do
                  xml.persname(role: 'creator')
                  xml.persname(role: 'contributor')
                end
                xml.langmaterial do
                  xml.language(langcode: 'en')
                end
                xml.physdesc do
                  xml.genreform # type
                end
              end
              xml.scopecontent # description
              xml.userestrict # rights
              xml.controlaccess do
                xml.subject # subject
                xml.persname(role: 'subject')
                xml.geogname(role: 'subject')
              end
              xml.dsc
            end
          end
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

        solr_doc = index_title_sorted!(solr_doc)
        solr_doc = index_type!(solr_doc)
        solr_doc = index_person!(solr_doc)
        solr_doc = index_all_metadata!(solr_doc)
        solr_doc = index_creator!(solr_doc)
        solr_doc = index_subject!(solr_doc)
        solr_doc = index_publisher!(solr_doc)
        solr_doc = index_identifiers!(solr_doc)
        solr_doc = index_dates!(solr_doc)
        solr_doc = index_date_ranges!(solr_doc)
        solr_doc = index_geospatial!(solr_doc)

        solr_doc
      end # to_solr

      def identifier_array_for_index
        identifier_id | identifier_public_id | identifier_url
      end

       # all_metadata - A SOLR index of all the text contained in the XML document
      def index_all_metadata!(solr_doc)
        solr_doc['all_metadata_tesim'] = [all_metadata_text]
        solr_doc
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
        persname_roles = named_with_roles(:pers_name_cvg)
        name_roles = named_with_roles(:name_cvg)
        corpname_roles = named_with_roles(:corp_name_cvg)
        famname_roles = named_with_roles(:fam_name_cvg)

        name_roles | persname_roles | corpname_roles | famname_roles
      end

      # Returns all metadata related to place/location subjects for Solr indexing
      # These are DRI Subject (Place) values
      # @return [Array<String>] array of all subject place metadata values for Solr indexing
      def subject_place_for_index
        named_with_roles(:geog_name_cvg)
      end

      # Returns all metadata related to temporal subjects for Solr indexing
      # These are DRI Subject (Temporal) values
      # @return [Array<String>] array of all subject temporal metadata values for Solr indexing
      def subject_temporal_for_index
        dcmi_period_array_for(:temporal_coverage) | dcmi_period_array_for(:date_cvg)
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
        dates = validated_hash(dates, :display, :normal)
        return unless dates

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
        dates = validated_hash(dates, :display, :normal)
        return unless dates

        ng_xml.search('/ead/eadheader/filedesc/publicationstmt/date').each(&:remove)
        pub_stmt = find_or_create_node('/ead/eadheader/filedesc/publicationstmt', '/ead/eadheader/filedesc', 'publicationstmt')

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
        creators = validated_hash(creators, :tag, :display, :role)
        return unless creators

        ng_xml.search('/ead/archdesc/did/origination/*[(local-name()="name" or local-name()="persname" or local-name()="famname" or local-name()="corpname") and not(@role="contributor")]').each(&:remove)
        origination = find_or_create_node('/ead/archdesc/did/origination', '/ead/archdesc/did', 'origination')

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
        origination = find_or_create_node('/ead/archdesc/did/origination', '/ead/archdesc/did', 'origination')

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
        people = validated_hash(people, :tag, :display, :role)
        return unless people

        ng_xml.search('/ead/archdesc/controlaccess/*[(local-name()="name" or local-name()="persname" or local-name()="famname" or local-name()="corpname") and not(@role="subject")]').each(&:remove)
        control_a = find_or_create_node('/ead/archdesc/controlaccess', '/ead/archdesc', 'controlaccess')

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
        dates = validated_hash(dates, :display, :normal, :datechar)
        return unless dates

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
        links = materials.select { |i| i[/\A#{URI.regexp(['http', 'https'])}\z/] }

        ng_xml.search('/ead/archdesc/relatedmaterial').each(&:remove)

        arch_desc = ng_xml.at('/ead/archdesc')
        # Add related materials that are not external links
        links.each do |link|
          next if link.empty?

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
        links = materials.select { |i| i[/\A#{URI.regexp(['http', 'https'])}\z/] }

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
        locations = validated_hash(locations, :type, :display)
        return unless locations

        ng_xml.search('/ead/archdesc/controlaccess/geogname[not(@role="subject")]').each(&:remove)
        control_a = find_or_create_node('/ead/archdesc/controlaccess', '/ead/archdesc', 'controlaccess')

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
        languages = validated_hash(languages, :langcode, :text)
        return unless languages

        ng_xml.search('/ead/archdesc/did/langmaterial/language').each(&:remove)
        lang_mat = find_or_create_node('/ead/archdesc/did/langmaterial', '/ead/archdesc/did', 'langmaterial')

        languages[:text].each_with_index do |lang, idx|
          next if lang.empty?

          node = Nokogiri::XML::Node.new('language', ng_xml)
          node.content = lang
          node[:langcode] = languages[:langcode][idx] unless languages[:langcode][idx].empty?
          lang_mat.add_child(node)
        end
      end

      # No parent to update as this object is a EAD ROOT Collection
      def update_parent_metadata(_parent, _full_metadata); end

      # Implement additional DRI metadata validations as this class does not inherit
      # from DRI::Metadata::Base
      # @return [Hash] the hash with any errors from validation
      def custom_validations
        errors = {}

        # Mandatory elements at collection-level
        errors[:title] = "can't be blank" unless metadata_present?(title)
        errors[:creator] = "can't be blank" unless metadata_present?(creator)
        errors[:description] = "can't be blank" unless metadata_present?(description)
        errors[:date] = "can't be blank" unless date_present?
        errors[:rights] = "can't be blank" unless metadata_present?(rights)

        # EAD-specific validation from best practices
        add_ead_level_errors!(errors)
        add_identifier_errors!(errors)

        errors
      end # custom_validations

      load_inherited_terminology

      private

      def metadata_present?(values)
        values.any?(&:present?)
      end

      def date_present?
        metadata_present?(creation_date) || metadata_present?(temporal_coverage)
      end

      def add_ead_level_errors!(errors)
        ead_level_ok = false
        ead_level_other_ok = false

        if DRI::Vocabulary.ead_level_values.include?(ead_level.first)
          ead_level_ok = metadata_present?(ead_level)
          ead_level_other_ok = metadata_present?(ead_level_other)
        end

        if ead_level.include?('otherlevel')
          errors[:ead_level_other] = "can't be blank" unless ead_level_other_ok
        elsif !ead_level_ok
          errors[:ead_level] = "can't be blank"
        end
      end

      # EADID validation: eadid must be present, and its @countrycode and
      # @mainagencycode (repository_code) attributes are compulsory.
      def add_identifier_errors!(errors)
        if !metadata_present?(identifier)
          errors[:identifier] = "can't be blank"
        elsif !metadata_present?(country_code) || !metadata_present?(repository_code)
          errors[:identifier] = 'invalid use'
          errors[:country_code] = "can't be blank" unless metadata_present?(country_code)
          errors[:repository_code] = "can't be blank" unless metadata_present?(repository_code)
        end
      end

      # Validates a Hash param has all the given keys (after symbolizing -
      # non-destructively, unlike the original's dates.symbolize_keys!,
      # which mutated whatever Hash object the caller passed in) and that
      # every one of those keys' values is the same size. Returns the
      # symbolized hash, or nil if invalid
      def validated_hash(hash, *keys)
        return nil unless hash.is_a?(Hash)

        hash = hash.symbolize_keys
        return nil unless keys.all? { |key| hash.key?(key) }
        return nil unless keys.map { |key| hash[key].size }.uniq.size <= 1

        hash
      end

      # Finds the node at xpath, or creates+appends a new <tag> under
      # parent_xpath if it doesn't exist yet.
      def find_or_create_node(xpath, parent_xpath, tag)
        node = ng_xml.at(xpath)
        return node if node

        parent = ng_xml.at(parent_xpath)
        new_node = Nokogiri::XML::Node.new(tag, ng_xml)
        parent.add_child(new_node)
        new_node
      end

      def index_title_sorted!(solr_doc)
        return solr_doc if title.empty?

        sorted_title = DRI::Metadata::Transformations.transform_title_for_sort(title[0])
        solr_doc[sortable_field('title_sorted', type: :string)] = [sorted_title] if sorted_title.present?

        solr_doc
      end

      def index_type!(solr_doc)
        solr_doc[searchable_field('type')] = resource_type
        solr_doc[facetable_field('type')] = resource_type
        solr_doc[searchable_field('type', type: :string)] = 'Collection'

        solr_doc
      end

      # EAD has several "name" tags, so we merge them together into the SOLR document
      def index_person!(solr_doc)
        people = person_array_for_index

        solr_doc[facetable_field('person')] = people
        solr_doc[searchable_field('person', type: :text)] = people | DRI::Metadata::Transformations.transform_name(people)

        solr_doc
      end

      def index_creator!(solr_doc)
        creators = creator_for_index

        solr_doc[facetable_field('creator')] = creators
        solr_doc[searchable_field('creator', type: :text)] = creators

        solr_doc
      end

      def index_subject!(solr_doc)
        subjects = subject_for_index
        solr_doc[searchable_field('subject')] = subjects
        solr_doc[facetable_field('subject')] = subjects

        names = subject_name_for_index
        solr_doc[searchable_field('name_coverage')] = names
        solr_doc[facetable_field('name_coverage')] = names

        places = subject_place_for_index
        solr_doc[searchable_field('geographical_coverage')] = places
        solr_doc[facetable_field('geographical_coverage')] = filter_uris(places)

        temporal = subject_temporal_for_index
        solr_doc[searchable_field('temporal_coverage')] = temporal
        solr_doc[facetable_field('temporal_coverage')] = filter_uris(temporal)

        solr_doc
      end

      def index_publisher!(solr_doc)
        solr_doc[searchable_field('publisher')] = publisher unless publisher == []
        solr_doc
      end

      def index_identifiers!(solr_doc)
        solr_doc['identifier_ssim'] = identifier_array_for_index
        solr_doc
      end

      def index_dates!(solr_doc)
        solr_doc[searchable_field('creation_date')] = dcmi_period_array_for(:creation_date) unless creation_date.empty?
        solr_doc[searchable_field('published_date')] = dcmi_period_array_for(:published_date) unless published_date.empty?
        # Indexing creation_date_idx is necessary for children, in case they inherit from the root collection
        solr_doc[searchable_field('creation_date_idx')] = creation_date_idx

        solr_doc
      end

      def index_date_ranges!(solr_doc)
        date_ranges = date_ranges_for_index # ALL the date ranges

        index_date_range!(solr_doc, transformed(date_ranges, 'creation_date'),
                           range_field: DRI::Metadata::Transformations::CREATION_DATE_RANGE_SOLR_FIELD,
                           year_field: DRI::Metadata::Transformations::CREATION_DATE_YEAR_SOLR_FIELD,
                           start_field: DRI::Metadata::Transformations::CREATION_DATE_RANGE_START_SOLR_FIELD,
                           end_field: DRI::Metadata::Transformations::CREATION_DATE_RANGE_END_SOLR_FIELD)

        index_date_range!(solr_doc, transformed(date_ranges, 'published_date'),
                           range_field: DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_SOLR_FIELD,
                           year_field: DRI::Metadata::Transformations::PUBLISHED_DATE_YEAR_SOLR_FIELD,
                           start_field: DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_START_SOLR_FIELD,
                           end_field: DRI::Metadata::Transformations::PUBLISHED_DATE_RANGE_END_SOLR_FIELD)

        index_date_range!(solr_doc, transformed(date_ranges, 'subject_date'),
                           range_field: DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_SOLR_FIELD,
                           start_field: DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_START_SOLR_FIELD,
                           end_field: DRI::Metadata::Transformations::SUBJECT_DATE_RANGE_END_SOLR_FIELD)

        solr_doc
      end

      def transformed(date_ranges, key)
        DRI::Metadata::Transformations.transform_date_ranges(date_ranges.select { |k, _v| k == key })
      end

      def index_geospatial!(solr_doc)
        geospatial_hash = DRI::Metadata::Transformations.transform_geospatial('geographical_coverage' => geocode_point | geocode_box)

        uris = geocode_logainm.select { |i| i[/\A#{URI.regexp(['http', 'https'])}\z/] } | reconciliation_uris
        if uris.present?
          linked_data = DRI::Metadata::Transformations.transform_geospatial('geographical_coverage' => uris)

          geospatial_hash[:coords].concat(linked_data[:coords])
          geospatial_hash[:name].concat(linked_data[:name])
          geospatial_hash[:json].concat(linked_data[:json])
        end

        solr_doc[DRI::Metadata::Transformations::GEOSPATIAL_SOLR_FIELD] = geospatial_hash[:coords] unless geospatial_hash[:coords].empty?
        solr_doc[searchable_field(DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD)] = geospatial_hash[:name] unless geospatial_hash[:name].empty?
        solr_doc[facetable_field(DRI::Metadata::Transformations::PLACENAME_SOLR_FIELD, type: :text)] = geospatial_hash[:name] unless geospatial_hash[:name].empty?
        solr_doc[searchable_field('geojson', type: :symbol)] = geospatial_hash[:json] unless geospatial_hash[:json].empty?

        solr_doc
      end
    end # class
  end # module
end # module
