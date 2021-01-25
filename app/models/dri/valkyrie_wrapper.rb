# frozen_string_literal: true
module DRI
  class ValkyrieWrapper < Valkyrie::Resource

    attribute :wrapped_object, Valkyrie::Types::Any, internal: true

    delegate :alternate_id, to: :wrapped_object
    delegate :create_date, to: :wrapped_object
    delegate :modified_date, to: :wrapped_object

    def attributes
      super.except(:wrapped_object)
    end

    def id
      return unless wrapped_object

      wrapped_object.alternate_id
    end

    def to_solr
      return {} unless wrapped_object
      wrapped_object.to_solr
    end
  end
end
