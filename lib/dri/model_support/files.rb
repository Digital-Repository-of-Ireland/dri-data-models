# DRI namespace
module DRI
  # ModelSupport namespace
  module ModelSupport
    module Files
      extend ActiveSupport::Concern
      require 'open-uri'
      require 'uri'
      require 'tempfile'
    end # module
  end # module
end # module
