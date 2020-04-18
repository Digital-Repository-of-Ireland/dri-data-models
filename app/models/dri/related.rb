module DRI
  class Related < ApplicationRecord
    self.table_name = 'dri_related'

    has_and_belongs_to_many :related, class_name: 'DRI::DigitalObject', join_table: 'digital_object_related'
  end
end
