module Sufia
  module GenericFile
    module MimeTypes
      extend ActiveSupport::Concern

      def pdf?
        self.class.pdf_mime_types.include? mime_type
      end

      def text?
        self.class.text_mime_types.include? mime_type
      end

      def image?
        self.class.image_mime_types.include? mime_type
      end

      def video?
        self.class.video_mime_types.include? mime_type
      end

      def audio?
        self.class.audio_mime_types.include? mime_type
      end

      def file_format
        return nil if mime_type.blank? && format_label.blank?
        return mime_type.split('/')[1] + ' (' + format_label.join(', ') + ')' unless mime_type.blank? || format_label.blank?
        return mime_type.split('/')[1] unless mime_type.blank?

        format_label
      end

      module ClassMethods
        def image_mime_types
          Settings.restrict.mime_types.image
        end

        def pdf_mime_types
          Settings.restrict.mime_types.pdf
        end

        def text_mime_types
          Settings.restrict.mime_types.text
        end

        def video_mime_types
          Settings.restrict.mime_types.video
        end

        def audio_mime_types
          Settings.restrict.mime_types.audio
        end
      end
    end
  end
end
