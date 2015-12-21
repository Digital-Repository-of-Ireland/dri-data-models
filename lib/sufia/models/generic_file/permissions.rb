# Sufia namespace
module Sufia
  # GenericFile namespace
  module GenericFile
    # Overwriting this module so that Sufia's default permissions don't kick in
    module Permissions
      extend ActiveSupport::Concern
    end
  end
end