# Represents a file stored on the local filesystem.

require 'pathname'

module DRI::ModelSupport
  module LocalFile
    # Write the file to the filesystem
    #
    def add_file(upload, opts = {})
      # object ID will be used in the MOAB directory name
      object_id = digital_object.noid

      self.version = digital_object.object_version || 1
      self.mime_type = opts[:mime_type]

      base_dir = opts[:directory].presence || File.join(content_path(object_id, version))
      FileUtils.mkdir_p(base_dir)

      self.path = File.join(base_dir, opts[:file_name])
      upload_to_file(upload)
    end

    # Remove the file from the filesystem if it exists
    # This has been disabled for now so that only soft delete is possible
    # TODO reenable this as an admin function
    def delete_file
      return if path.nil? || !File.exist?(path)

      File.delete(path)

      pn = Pathname.new(path)
      FileUtils.remove_dir(pn.dirname, force: true)
    end

    private

      def local_storage_dir
        Rails.root.join(Settings.dri.files)
      end

      def local_storage_dir
        Rails.root.join(Settings.dri.files)
      end

      def version_path(object_id, version)
        File.join(local_storage_dir, build_hash_dir(object_id), version_string(version))
      end

      # data path
      def data_path(object_id, version)
        File.join(version_path(object_id, version), "data")
      end

      # output: partial path string e.g. "1c/18/df/87/1c18df87m/v0001"
      def content_path(object_id, version)
        File.join(data_path(object_id, version), "content")
      end

      # Return formatted version number for the file path
      # versions start at 0, but MOAB expects v0001 as first version
      # output: incremented & formatted version number String of format vxxxx
      def version_string(version)
        'v%04d' % version
      end

      # Return the hash part of the file path
      # input (optional): batch String (fedora object id)
      # output: partial path String e.g. "1c/18/df/87/1c18df87m"
      def build_hash_dir(batch)
        dir = ""
        index = 0

        4.times {
          dir = File.join(dir, batch[index..index+1])
          index += 2
        }

        File.join(dir, batch)
      end

      def upload_to_file(upload)
        if upload.respond_to?('path')
          FileUtils.cp(upload.path, path)
        else
          File.open(path, 'wb') { |f| f.write(upload.read) }
        end
        File.chmod(0644, path)
      end

    end
end
