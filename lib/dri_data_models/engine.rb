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

    ActiveFedora::Base.translate_uri_to_id = ActiveFedora::Noid.config.translate_uri_to_id
    ActiveFedora::Base.translate_id_to_uri = ActiveFedora::Noid.config.translate_id_to_uri

    config.generators do |g|
      g.test_framework :rspec, :fixture => true
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end

    initializer :append_migrations do |app|
      unless app.root.to_s.match root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end
  end
end
