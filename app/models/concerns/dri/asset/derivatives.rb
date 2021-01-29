module DRI
  module Asset
    module Derivatives
      extend ActiveSupport::Concern

      included do
        include Hydra::Derivatives
      end

      def create_derivatives(_filename)
        case mime_type
        when *self.class.pdf_mime_types
          Hydra::Derivatives::PdfDerivatives.create(
            self,
            source: :content,
            outputs: [{ label: :thumbnail, format: 'jpg', size: '338x493' }]
          )
        when *self.class.text_mime_types
          Hydra::Derivatives::DocumentDerivatives.create(
            self,
            source: :content,
            outputs: [{ format: 'jpg', size: '200x150>', label: :thumbnail }]
          )
        when *self.class.audio_mime_types
          Hydra::Derivatives::AudioDerivatives.create(
            self,
            source: :content,
            outputs: [{ format: 'mp3', label: :mp3 }, { format: 'ogg', label: :ogg }]
          )
        when *self.class.video_mime_types
          Hydra::Derivatives::VideoDerivatives.create(
            self,
            source: :content,
            outputs: [
              { format: 'webm', label: :webm },
              { format: 'mp4', label: :mp4 },
              { format: 'jpg', label: 'thumbnail' }
            ]
          )
        when *self.class.image_mime_types
          Hydra::Derivatives::ImageDerivatives.create(
            self,
            source: :content,
            outputs: [{ format: 'jpg', size: '200x150>', label: :thumbnail }]
          )
        end
      end
    end
  end
end
