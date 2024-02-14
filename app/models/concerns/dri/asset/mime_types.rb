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
      self.class.text_mime_types.include?(self.mime_type) && !self.class.restricted_3D_extensions.include?(extension)
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

    # Check if 3D file
    # @return [Boolean] true if mime_type included in audio mimetypes
    def threeD?
      self.class._3D_mime_types.include?(self.mime_type) && self.class.restricted_3D_extensions.include?(extension)
    end

    def interactive_resource?
      self.class.interactive_resource_mime_types.include?(self.mime_type) && self.class.restricted_interactive_resource_extensions.include?(extension)
    end

    def extension
      File.extname(self.label).downcase if self.label
    end

    # Formatting the file format label for display
    # @return [String] formatted file format label; nil if not available
    def file_format
      return nil if mime_type.blank? && format_label.blank?
      return mime_type.split('/')[1] + ' (' + format_label.join(', ') + ')' unless mime_type.blank? || format_label.blank?
      return mime_type.split('/')[1] if mime_type.present?

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

      def _3D_mime_types
        ::Settings.restrict.mime_types._3D
      end

      def interactive_resource_mime_types
        ::Settings.restrict.mime_types.interactive_resource
      end

      # Restrict mimetypes for 3D
      def _3D_file_formats
        ::Settings.restrict.file_formats._3D
      end

      # Restrict mimetypes for Web Archive
      def interactive_resource_file_formats
        ::Settings.restrict.file_formats.interactive_resource
      end

      def restricted_text_extensions
        ::Settings.restrict.extensions.restricted_text
      end

      def restricted_3D_extensions
        ::Settings.restrict.extensions.restricted_3D
      end

      def restricted_interactive_resource_extensions
        ::Settings.restrict.extensions.restricted_interactive_resource
      end

    end
  end
end
