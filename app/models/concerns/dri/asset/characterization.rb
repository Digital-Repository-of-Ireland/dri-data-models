module DRI::Asset
  module Characterization
      extend ActiveSupport::Concern
      included do
        has_subresource :characterization, class_name: 'FitsDatastream'

        delegate :format_label,          to: :characterization
        delegate :file_size,             to: :characterization
        delegate :last_modified,         to: :characterization
        delegate :filename,:filename=,   to: :characterization
        delegate :original_checksum, to: :characterization
        delegate :rights_basis,      to: :characterization
        delegate :copyright_basis,   to: :characterization
        delegate :copyright_note,    to: :characterization
        delegate :well_formed,       to: :characterization
        delegate :valid,             to: :characterization
        delegate :message,           to: :characterization
        delegate :file_title,        to: :characterization
        delegate :file_author,       to: :characterization
        delegate :page_count,        to: :characterization
        delegate :file_language,     to: :characterization
        delegate :word_count,        to: :characterization
        delegate :character_count,   to: :characterization
        delegate :paragraph_count,   to: :characterization
        delegate :line_count,        to: :characterization
        delegate :table_count,       to: :characterization
        delegate :graphics_count,    to: :characterization
        delegate :byte_order,        to: :characterization
        delegate :compression,       to: :characterization
        delegate :color_space,       to: :characterization
        delegate :profile_name,      to: :characterization
        delegate :profile_version,   to: :characterization
        delegate :orientation,       to: :characterization
        delegate :color_map,         to: :characterization
        delegate :image_producer,    to: :characterization
        delegate :capture_device,    to: :characterization
        delegate :scanning_software, to: :characterization
        delegate :exif_version,      to: :characterization
        delegate :gps_timestamp,     to: :characterization
        delegate :latitude,          to: :characterization
        delegate :longitude,         to: :characterization
        delegate :character_set,     to: :characterization
        delegate :markup_basis,      to: :characterization
        delegate :markup_language,   to: :characterization
        delegate :bit_depth,         to: :characterization
        delegate :channels,          to: :characterization
        delegate :data_format,       to: :characterization
        delegate :offset,            to: :characterization
        delegate :frame_rate,        to: :characterization
      end

      def file_size
       characterization.file_size
      end

      def file_size=(file_size)
       characterization.file_size = file_size
      end

      def file_title
       characterization.file_title
      end

      def file_title=(file_title)
       characterization.file_title = file_title
      end

      def mime_type
       characterization.identification.identity.mime_type.first
      end

      def mime_type=(mime_type)
       characterization.identification.identity.mime_type = mime_type
      end

      def width
        characterization.width.blank? ? characterization.video_width : characterization.width
      end

      def height
        characterization.height.blank? ? characterization.video_height : characterization.height
      end

      def duration
        characterization.duration.blank? ? characterization.video_duration : characterization.duration
      end

      def sample_rate
        characterization.sample_rate.blank? ? characterization.video_sample_rate : characterization.sample_rate
      end

      ## Extract the metadata from the content datastream and record it in the characterization datastream
      def characterize
        metadata = extract_metadata
        characterization.ng_xml = metadata if metadata.present?
        append_metadata
        self.filename = [self.label]
        save
      end

      # Populate GenericFile's properties with fields from FITS (e.g. Author from pdfs)
      def append_metadata
        fits_to_desc_mapping = {
          :file_title => :title,
          :file_author => :creator
        }

        terms = characterization_terms
        fits_to_desc_mapping.each_pair do |k, v|
          next unless terms.key?(k)
          Array.wrap(terms[k]).each do |term_value|
            proxy_term = send(v)
            if proxy_term.is_a?(Array)
              proxy_term << term_value unless proxy_term.include?(term_value)
            else
              # these are single-valued terms which cannot be appended to
              send("#{v}=", term_value)
            end
          end
        end
      end

      def characterization_terms
        h = {}
        FitsDatastream.terminology.terms.each_pair do |_k, v|
          next unless v.respond_to? :proxied_term
          term = v.proxied_term
          begin
            value = send(term.name)
            h[term.name] = value unless value.empty?
          rescue NoMethodError
            next
          end
        end
        h
      end
    end
end
