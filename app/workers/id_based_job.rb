# frozen_string_literal: true
class IdBasedJob
  def queue_name
    :id_based
  end

  attr_accessor :id

  def initialize(id)
    self.id = id
  end

  def object
    @object ||= DRI::Identifier.retrieve_object(id)
  end

  alias generic_file object
  alias generic_file_id id

  def run
    raise "Define #run in a subclass"
  end
end
