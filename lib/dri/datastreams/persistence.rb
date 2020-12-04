module DRI::Datastreams
 module Persistence

    def persisted_remote_content
      return if new_record?
      @ds_content ||= retrieve_content
    end

    def content_changed?
      return true if new_record? && !local_or_remote_content(false).blank?
      local_or_remote_content(false) != @ds_content
    end

    def changed_for_autosave?
      content_changed?
    end

    def changed?
      super || content_changed?
    end

    # serializes any changed data into the content field
    def serialize!
    end

    def persisted_content=(string_or_io)
      attribute_will_change!('content') unless @content == string_or_io
      @content = string_or_io
    end

    def persisted_content
      local_or_remote_content(true)
    end

    def _create_record(_options = {})
      return false if content.nil?
      self.datastream_content = content
      super()
    end

    def _update_record(_options = {})
      return true unless content_changed?
      self.datastream_content = content
      super()
    end

    private

      # Rack::Test::UploadedFile is often set via content=, however it's not an IO, though it wraps an io object.
      def behaves_like_io?(obj)
        [IO, Tempfile, StringIO].any? { |klass| obj.is_a? klass } || (defined?(Rack) && obj.is_a?(Rack::Test::UploadedFile))
      end

      def retrieve_content
        datastream_content
      end

      def uploaded_file?(payload)
        defined?(ActionDispatch::Http::UploadedFile) && payload.instance_of?(ActionDispatch::Http::UploadedFile)
      end

      def local_or_remote_content(ensure_fetch = true)
        @content ||= ensure_fetch ? remote_content : @ds_content unless new_record?
        @content.rewind if behaves_like_io?(@content)
        @content
      end
  end
end
