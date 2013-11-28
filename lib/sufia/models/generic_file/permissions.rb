# Overwriting this module so that Sufia's default permissions don't kick in
module Sufia
  module GenericFile
    module Permissions
      extend ActiveSupport::Concern
    end
  end
end