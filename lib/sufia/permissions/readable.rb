module Sufia
  module Permissions
    module Readable
      extend ActiveSupport::Concern

      def public?
        governing_object = self.batch

        while governing_object.master_file_access.nil? || governing_object.master_file_access == "inherit" 
          governing_object = governing_object.governing_collection
        end        

        governing_object.master_file_access == "public"
      end

      def preservation?
        self.preservation_only == "true"
      end

      def registered?
        read_groups.include?('registered')
      end

      def private?
        !(public? || registered?)
      end

    end
  end
end
