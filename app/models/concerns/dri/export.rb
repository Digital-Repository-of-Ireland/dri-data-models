module DRI
  module Export
    # MIME: 'application/x-endnote-refer'
    def export_as_endnote
      end_note_format = {
        '%T' => [:title, lambda { |x| x.first }],
        '%Q' => [:title, lambda { |x| x.drop(1) }],
        '%A' => [:creator],
        # '%C' => [:publication_place],
        '%D' => [:creation_date],
        '%8' => [:published_date],
        '%E' => [:contributor],
        '%I' => [:publisher],
        # '%J' => [:series_title],
        # '%@' => [:isbn],
        # '%U' => [:related_url],
        # '%7' => [:edition_statement],
        # '%R' => [:persistent_url],
        '%X' => [:description],
        '%G' => [:language],
        # '%[' => [:date_modified],
        '%9' => [:type],
        # '%~' => Application.config.application_name,
        '%W' => 'Digital Repository of Ireland'
      }
      text = []
      text << '%0 Object'
      end_note_format.each do |endnote_key, mapping|
        if mapping.is_a? String
          values = [mapping]
        else
          values = self.send(mapping[0]) if self.respond_to? mapping[0]
          values = mapping[1].call(values) if mapping.length == 2
          values = [values] unless values.is_a? Array
        end
        next if values.empty? or values.first.nil?
        spaced_values = values.join('; ')
        text << "#{endnote_key} #{spaced_values}"
      end

      text.join("\n")
    end

    # Export the citation in x-openurl-ctx-kev format
    # MIME type: 'application/x-openurl-ctx-kev'
    # @return [String] the citation as text
    def export_as_openurl_ctx_kev
      export_text = []
      export_text << 'url_ver=Z39.88-2004&ctx_ver=Z39.88-2004&rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Adc&rfr_id=info%3Asid%2Fblacklight.rubyforge.org%3Agenerator'
      field_map = {
        title: 'title',
        creator: 'creator',
        subject: 'subject',
        description: 'description',
        publisher: 'publisher',
        contributor: 'contributor',
        creation_date: 'date',
        type: 'format',
        identifier: 'identifier',
        language: 'language',
        # :tag => 'relation',
        geographical_coverage: 'coverage',
        rights: 'rights'
      }
      field_map.each do |element, kev|
        values = self.send(element)
        next if values.empty? || values.first.nil?
        values.each do |value|
          export_text << "rft.#{kev}=#{CGI.escape(value)}"
        end
      end

      export_text.join('&') unless export_text.blank?
    end

    # Exports the citation in DRI format
    # @return [String] the citation as html-safe text
    def export_as_dri_citation
      text = ''
     
      authors_list = []
      authors_list_final = []
       
      authors = author_list
      authors.each do |author|
        next if author.blank?
        authors_list.push(author)
      end
      authors_list.each do |author|
        if author == authors_list.first # first
          authors_list_final.push(author.strip)
        elsif author == authors_list.last # last
          authors_list_final.push(', &amp; ' + author.strip)
        else # all others
          authors_list_final.push(', ' + author.strip)
        end
      end
      text << authors_list_final.join

      unless text.blank?
        if text[-1, 1] != '.'
          text << '. '
        else
          text << ' '
        end
      end 
      
      # Get Pub Date
      text << '(' + setup_pub_date('dri') + ') ' unless setup_pub_date('dri').nil?

      title_info = ''
      title.each do |t|
        title_info << clean_end_punctuation(CGI.escapeHTML(t)).strip + ', '
      end

      text << title_info unless title_info.blank?

      # Set database name
      text << setup_database_name 

      # Set depositing institute
      depositing_institute = self.depositing_institute.first

      if depositing_institute.blank?
        gov = self
        while depositing_institute.blank?
          gov = gov.governing_collection
          break if gov.nil?
          depositing_institute = gov.depositing_institute.first
        end
      end
      text << ", #{depositing_institute} [Depositing Institution]" unless depositing_institute.blank?

      text << ", DOI: #{doi.first}" unless doi.blank?

      text.html_safe
    end

    # Exports the citation in APA format
    # @return [String] the citation as html-safe text
    def export_as_apa_citation
      text = ''
      authors_list = []
      authors_list_final = []

      # setup formatted author list
      authors = author_list
      authors.each do |author|
        next if author.blank?
        authors_list.push(abbreviate_name(author))
      end
      authors_list.each do |author|
        if author == authors_list.first # first
          authors_list_final.push(author.strip)
        elsif author == authors_list.last # last
          authors_list_final.push(', &amp; ' + author.strip)
        else # all others
          authors_list_final.push(', ' + author.strip)
        end
      end
      text << authors_list_final.join
      unless text.blank?
        if text[-1, 1] != '.'
          text << '. '
        else
          text << ' '
        end
      end
      # Get Pub Date
      text << '(' + setup_pub_date('apa') + '). ' unless setup_pub_date('apa').nil?

      # setup title info
      title_info = setup_title_info
      text << '<i>' + title_info + '</i> ' unless title_info.nil?

      # Publisher info
      text << setup_pub_info unless setup_pub_info.nil?
      text += '.' if !text.blank? && text[-1, 1] != '.'

      text << setup_database_name

      text << " Retrieved #{access_date_chicago}."

      text << " doi: #{doi}" unless doi.nil?

      text.html_safe
    end

    # Exports the citation in MLA format
    # @return [String] the citation as html-safe text
    def export_as_mla_citation
      text = ''
      authors_final = []

      # setup formatted author list
      authors = author_list

      if authors.length < 4
        authors.each do |author|
          if author == authors.first # first
            authors_final.push(author)
          elsif author == authors.last # last
            authors_final.push(', and ' + name_reverse(author) + '.')
          else # all others
            authors_final.push(', ' + name_reverse(author))
          end
        end
        text << authors_final.join
        unless text.blank?
          if text[-1, 1] != '.'
            text << '. '
          else
            text << ' '
          end
        end
      else
        text << authors.first + ', et al. '
      end
      # setup title
      title_info = setup_title_info
      text << '<i>' + mla_citation_title(title_info) + '</i> ' unless title.blank?

      # Publication
      text << setup_pub_info unless setup_pub_info.nil?

      # Get Pub Date
      date = setup_pub_date('mla')
      date = 'n.d' if date.nil?

      text << ', ' + date
      text << '.' if !text.blank? && text[-1, 1] != '.'

      # Set database name
      text << setup_database_name

      text << ' Web. '
      text << access_date_mla + '.'

      text << " <#{doi}>" unless doi.nil?

      text.html_safe
    end

    # Exports the citation in CHICAGO format
    # @return [String] the citation as html-safe text
    def export_as_chicago_citation
      author_text = ''
      authors = all_authors
      unless authors.blank?
        if authors.length > 10
          authors.each_with_index do |author, index|
            next unless index < 7

            if index == 0
              author_text << "#{author}"
              if author.ends_with?(',')
                author_text << ' '
              else
                author_text << ', '
              end
            else
              author_text << "#{name_reverse(author)}, "
            end
          end
          author_text << ' et al.'
        elsif authors.length > 1
          authors.each_with_index do |author, index|
            if index == 0
              author_text << "#{author}"
              if author.ends_with?(',')
                author_text << ' '
              else
                author_text << ', '
              end
            elsif index + 1 == authors.length
              author_text << "and #{name_reverse(author)}."
            else
              author_text << "#{name_reverse(author)}, "
            end
          end
        else
          author_text << authors.first
        end
      end
      title_info = ''
      title_info << citation_title(clean_end_punctuation(CGI.escapeHTML(title.first)).strip) unless title.blank?

      pub_info = ''
      place = '' # self.based_near.first
      publisher = self.publisher.first
      unless place.blank?
        place = CGI.escapeHTML(place)
        pub_info << place
        pub_info << ': ' unless publisher.blank?
      end

      published_date = setup_pub_date('chicago')

      unless publisher.blank?
        publisher = CGI.escapeHTML(publisher)
        pub_info << publisher
        pub_info << ', ' unless published_date.nil?
      end
      pub_info << published_date unless published_date.nil?

      citation = ''
      citation << "#{author_text} " unless author_text.blank?
      citation << "<i>#{title_info}.</i> " unless title_info.blank?
      citation << "#{pub_info}." unless pub_info.blank?
      citation << "#{setup_database_name}"
      citation << " Accessed #{access_date_chicago}."
      citation << " doi: #{doi}." unless doi.nil?

      citation.html_safe
    end

    private

    def setup_database_name
      'Digital Repository of Ireland [Distributor]'
    end

    def access_date_mla
      date = Time.now
      date.strftime('%d %b, %Y')
    end

    def access_date_chicago
      date = Time.now
      date.strftime('%B %-d, %Y')
    end

    def setup_pub_date(format)
      first_date = published_at
      unless first_date.blank?
        first_date = CGI.escapeHTML(first_date)
        date = Time.parse(first_date) # first_date.gsub(/[^0-9|n\.d\.]/, "")[0,4]
        date_value = date.strftime('%Y, %B %-d') if format.eql?('apa')
        date_value = date.strftime('%d %B %Y') if format.eql?('mla')
        date_value = date.strftime('%Y') if format.eql?('chicago')
        date_value = date.strftime('%Y') if format.eql?('dri')
        return nil if date_value.nil?
      end

      clean_end_punctuation(date_value) if date_value
    end

    def setup_pub_info
      text = ''
      place = '' # self.based_near.first
      publisher = self.publisher.first

      unless place.blank?
        place = CGI.escapeHTML(place)
        text << place
        text << ': ' unless publisher.blank?
      end

      unless publisher.blank?
        publisher = CGI.escapeHTML(publisher)
        text << publisher
      end

      return nil if text.strip.blank?

      clean_end_punctuation(text.strip)
    end

    def mla_citation_title(text)
      no_upcase = %w(a an and but by for it of the to with)
      new_text = []
      word_parts = text.split(' ')
      word_parts.each do |w|
        if !no_upcase.include? w
          new_text.push(w.capitalize)
        else
          new_text.push(w)
        end
      end

      new_text.join(' ')
    end

    def citation_title(title_text)
      prepositions = %w(a about across an and before but by for it of the to with without)
      new_text = []
      title_text.split(' ').each_with_index do |word, index|
        if (index == 0 && word != word.upcase) ||
           (word.length > 1 && word != word.upcase && !prepositions.include?(word))
          # the split("-") will handle the capitalization of hyphenated words
          new_text << word.split('-').map!(&:capitalize).join('-')
        else
          new_text << word
        end
      end
      new_text.join(' ')
    end

    def setup_title_info
      text = ''
      title = self.title.first
      unless title.blank?
        title = CGI.escapeHTML(title)
        title_info = clean_end_punctuation(title.strip)
        text << title_info
      end

      return nil if text.strip.blank?

      clean_end_punctuation(text.strip) + '.'
    end

    def clean_end_punctuation(text)
      return text[0, (text.length - 1)] if %w(. , : ; /).include? text[-1, 1]

      text
    end

    def author_list
      creator.map { |author| clean_end_punctuation(CGI.escapeHTML(author)) }.uniq
    end

    def all_authors
      authors = creator

      return nil if authors.empty?

      authors.map { |author| CGI.escapeHTML(author) }
    end

    def abbreviate_name(name)
      abbreviated_name = ''
      name = name.join('') if name.is_a? Array
      # make sure we handle "Cher" correctly
      return name if !name.include?(' ') && !name.include?(',')
      surnames_first = name.include?(',')
      delimiter = surnames_first ? ', ' : ' '
      name_segments = name.split(delimiter)
      given_names = surnames_first ? name_segments.last.split(' ') : name_segments.first.split(' ')
      surnames = surnames_first ? name_segments.first.split(' ') : name_segments.last.split(' ')
      abbreviated_name << surnames.join(' ')
      abbreviated_name << ', '
      abbreviated_name << given_names.map { |n| "#{n[0]}." }.join if given_names.is_a? Array
      abbreviated_name << "#{given_names[0]}." if given_names.is_a? String

      abbreviated_name
    end

    def name_reverse(name)
      name = clean_end_punctuation(name)
      return name unless name =~ /,/
      temp_name = name.split(', ')

      temp_name.last + ' ' + temp_name.first
    end
  end
end
