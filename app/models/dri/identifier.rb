# frozen_string_literal: true
module DRI
  class Identifier < ActiveRecord::Base
    belongs_to :identifiable, polymorphic: true

    def self.retrieve_object(pid)
      find_by(alternate_id: pid).try(:identifiable)
    end

    def self.retrieve_object!(pid)
      object = retrieve_object(pid)
      raise(ActiveRecord::RecordNotFound, "Couldn't find object with 'identifier'=#{pid}") unless object

      object
    end

    def self.object_exists?(pid)
      !DRI::Identifier.find_by(alternate_id: pid).try(:identifiable).nil?
    end

    def self.gone?(pid)
      identifier = find_by(alternate_id: pid)
      identifier && !identifier.identifiable.class.exists?(identifier.identifiable_id)
    end
  end
end
