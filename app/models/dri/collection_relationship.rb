# frozen_string_literal: true
module DRI
  class CollectionRelationship < ApplicationRecord
    belongs_to :digital_object, class_name: 'DRI::DigitalObject'
    belongs_to :collection_relative, class_name: 'DRI::DigitalObject'
  end
end
