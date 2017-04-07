module DriDataModels
  require 'rails'
  require 'hydra/head'
  require 'hydra-collections'
  require 'hydra/derivatives'
  require 'active_fedora/noid'
  require 'resque/server'
  require 'dri/resque'
  require 'rdf/vocab'

  # RoR rails engine class implementation for the gem
  class Engine < ::Rails::Engine
    config.autoload_paths += %W(#{config.root}/app/models/datastreams)
 
    isolate_namespace DriDataModels
  end
end
