module DRI
  module Metadata
    class Mods < DRI::Datastreams::OmDatastream
      # Extracts a Mods datastream's metadata into the Hash shape the DRI UI
      # edit form expects.
      #
      class TermsHashExtractor
        def initialize(datastream)
          @datastream = datastream
        end

        # @return [Hash] Hash of DRI MODS metadata - see Mods#retrieve_terms_hash for the full shape
        def call
          terms_hash = {}
          terms_hash[:title] = datastream.title

          terms_hash[:roles] = names_hash
          terms_hash[:desc_abstract] = datastream.desc_abstract
          terms_hash[:desc_toc] = datastream.desc_toc
          terms_hash[:desc_note] = datastream.desc_note
          terms_hash[:desc_physdesc_note] = datastream.desc_physdesc_note
          terms_hash[:rights] = datastream.rights
          terms_hash[:language] = datastream.mods_language_text
          terms_hash[:resource_type] = type_hash
          terms_hash[:mods_genre] = genre_hash
          terms_hash[:origin_metadata] = origin_metadata_array
          terms_hash[:subject_metadata] = subjects_array

          terms_hash
        end

        private

        attr_reader :datastream

        def ng_xml
          datastream.ng_xml
        end

        # Creator, contributor and any name
        def names_hash
          hash = { 'name' => [], 'type' => [], 'authority' => [] }

          ng_xml.search('/mods:mods/mods:name', MODS_NS_MAPPING).each do |node|
            part_node = node.at('./mods:namePart', MODS_NS_MAPPING)
            role_code = node.at('./mods:role/mods:roleTerm[@type="code"]', MODS_NS_MAPPING)
            next if part_node.nil? || role_code.nil?
            next if role_code.nil? || DRI::Vocabulary.marc_relators_creator.key?(role_code.content)

            hash['authority'] << (node['authority'] ? node['authority'] : '')
            hash['name'] << part_node.content
            hash['type'] << "role_#{role_code.content}"
          end

          hash
        end

        def type_hash
          hash = { collection: datastream.collection?, content: [] }

          ng_xml.search('/mods:mods/mods:typeOfResource', MODS_NS_MAPPING).each do |node|
            hash[:content] << node.content
          end

          hash
        end

        def genre_hash
          hash = { authority: [], content: [] }

          ng_xml.search('/mods:mods/mods:genre', MODS_NS_MAPPING).each do |node|
            hash[:content] << node.content
            hash[:authority] << (node['authority'] ? node['authority'] : '')
          end

          hash
        end

        def origin_metadata_array
          array = []
          origin_info_nodes = ng_xml.search('/mods:mods/mods:originInfo', MODS_NS_MAPPING)

          origin_info_nodes.each do |origin|
            origin_info_hash = {}
            index = 0

            origin.children.select(&:element?).each do |elem|
              tag = elem.name

              case tag
              when 'place'
                place_hash = { tag: 'place', content: '' }
                p_term = elem.at('./mods:placeTerm', MODS_NS_MAPPING)
                place_hash[:content] = p_term.content
                origin_info_hash["#{index}"] = place_hash
              when 'issuance', 'publisher', 'edition', 'frequency'
                origin_info_hash["#{index}"] = { tag: tag, content: elem.content }
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
              end

              index += 1
            end

            array << origin_info_hash
          end

          array
        end

        # Subjects: topic, name_coverage, temporal_coverage, geographical_coverage
        def subjects_array
          array = []
          subject_nodes = ng_xml.search('/mods:mods/mods:subject', MODS_NS_MAPPING)

          subject_nodes.each do |snode|
            subj_hash = { values: [], authority: '' }
            subj_hash[:authority] = snode[:authority] unless snode[:authority].nil?

            snode.children.select(&:element?).each do |node|
              value_hash = subject_value_hash(node, snode)
              subj_hash[:values] << value_hash if value_hash
            end

            array << subj_hash
          end

          array
        end

        def subject_value_hash(node, snode)
          case node.name
          when 'topic'
            { tag: 'topic', content: node.content }
          when 'name'
            name_value_hash(node)
          when 'temporal'
            temporal_value_hash(node, snode)
          when 'geographic'
            geographic_value_hash(node)
          end
        end

        def name_value_hash(node)
          name_hash = { tag: 'name', display: '', role: '' }
          node_name = node.at('./mods:namePart', MODS_NS_MAPPING)
          return nil if node_name.nil?

          name_hash[:display] = node_name.content
          node_role = node.at('./mods:role/mods:roleTerm[@type="code"]', MODS_NS_MAPPING)
          name_hash[:role] = node_role.content unless node_role.nil?

          name_hash
        end

        def temporal_value_hash(node, snode)
          temporal_hash = { tag: 'temporal', start: '', end: '', encoding: '' }

          case node['point']
          when 'start'
            temporal_hash[:start] = node.content
            end_node = snode.children.select { |n| n['point'] == 'end' }
            temporal_hash[:end] = end_node.first.content unless end_node.empty?
          when 'end'
            return nil
          else
            temporal_hash[:start] = node.content
          end
          temporal_hash[:encoding] = node[:encoding] unless node[:encoding].nil?

          temporal_hash
        end

        def geographic_value_hash(node)
          geo_hash = { tag: 'geographic', content: node.content }
          if node['authority'].present? && node['authority'] == 'logainm'
            geo_hash[:uri] = node['valueURI'] if node['valueURI'].present?
          end
          geo_hash
        end
      end
    end
  end
end
