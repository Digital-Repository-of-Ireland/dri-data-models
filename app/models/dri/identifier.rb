module DRI
  class Identifier < ActiveRecord::Base
    belongs_to :identifiable, polymorphic: true

    def self.retrieve_object(pid)
      identifier = find_by(alternate_id: pid)
      return nil unless identifier
      identifier.identifiable
    end

    def self.retrieve_object!(pid)
      identifier = find_by!(alternate_id: pid)
      identifier.identifiable
    end

    def self.object_exists?(pid)
      identifier = find_by(alternate_id: pid)
      return false unless identifier.try(:identifiable)
      identifier.identifiable.class.exists?(identifier.identifiable_id)
    end

    def self.gone?(pid)
      identifier = find_by(alternate_id: pid)
      identifier && !identifier.identifiable.class.exists?(identifier.identifiable_id)
    end
  end
end