module DriDataModels
  require 'rails'
  require 'hydra/head'
  require 'hydra-collections'
  require 'sufia/models'

  # RoR rails engine class implementation for the gem
  class Engine < ::Rails::Engine
    config.autoload_paths += %W(#{config.root}/lib/sufia/models/jobs)
    config.autoload_paths += %W(#{config.root}/app/models/datastreams)
 
    isolate_namespace DriDataModels
  end
end
