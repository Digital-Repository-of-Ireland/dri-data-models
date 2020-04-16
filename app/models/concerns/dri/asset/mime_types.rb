module DRI::Asset
  module MimeTypes
      extend ActiveSupport::Concern
      # Check if pdf file
      # @return [Boolean] true if mime_type included in pdf mimetypes
      def pdf?
        self.class.pdf_mime_types.include? mime_type
      end

      # Check if text file
      # @return [Boolean] true if mime_type included in text mimetypes
      def text?
        self.class.text_mime_types.include? mime_type
      end

      # Check if image file
      # @return [Boolean] true if mime_type included in image mimetypes
      def image?
        self.class.image_mime_types.include? mime_type
      end

      # Check if video file
      # @return [Boolean] true if mime_type included in video mimetypes
      def video?
        self.class.video_mime_types.include? mime_type
      end

      # Check if audio file
      # @return [Boolean] true if mime_type included in audio mimetypes
      def audio?
        self.class.audio_mime_types.include? mime_type
      end

      # Formatting the file format label for display
      # @return [String] formatted file format label; nil if not available
      def file_format
        return nil if mime_type.blank? && format_label.blank?
        return mime_type.split('/')[1] + ' (' + format_label.join(', ') + ')' unless mime_type.blank? || format_label.blank?
        return mime_type.split('/')[1] unless mime_type.blank?

        format_label
      end

      # ClassMethods
      module ClassMethods
        # Restrict mimetypes for images
        def image_mime_types
          ::Settings.restrict.mime_types.image
        end

        # Restrict mimetypes for pdf
        def pdf_mime_types
          ::Settings.restrict.mime_types.pdf
        end

        # Restrict mimetypes for text
        def text_mime_types
          ::Settings.restrict.mime_types.text
        end

        # Restrict mimetypes for video
        def video_mime_types
          ::Settings.restrict.mime_types.video
        end

        # Restrict mimetypes for audio
        def audio_mime_types
          ::Settings.restrict.mime_types.audio
        end
      end
    end
end
