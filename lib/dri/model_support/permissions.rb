# DRI namespace
module DRI
  #ModelSupport namespace
  module ModelSupport
    # Override Hydra permissions
    module Permissions
      extend ActiveSupport::Concern

      included do
        include Hydra::AccessControls::Permissions
      end
    end
  end
end
