# frozen_string_literal: true
module DRI::Asset
  # Permissions namespace
  module Permissions
    module Readable
      extend ActiveSupport::Concern

      # Determine whether an object has public access status
      # @return [Boolean] true if public; false otherwise
      def public?
        governing_object = digital_object
        while governing_object.master_file_access.blank? || governing_object.master_file_access == 'inherit'
          governing_object = governing_object.governing_collection
          return false if governing_object.nil?
        end

        governing_object.master_file_access == 'public'
      end

      # Determine whether the object has a preservation only access status
      # @return [Boolean] true if preservation; false otherwise
      def preservation?
        preservation_only == true
      end

      # Determine whether the object has a registered access status
      # @return [Boolean] true if registered; false otherwise
      def registered?
        governing_object = digital_object
        while governing_object.read_groups.blank?
          governing_object = governing_object.governing_collection
          return false if governing_object.nil?
        end

        governing_object.read_groups.include?('registered')
      end

      # Determine whether the object has a private access status
      # @return [Boolean] true if private; false otherwise
      def private?
        !(public? || registered?)
      end
    end
  end
end
