module DriDataModels
  require 'rails'
  require 'hydra/derivatives'
  require 'noid-rails'
  require 'resque/server'
  require 'dri/resque'
  require 'rdf/vocab'
  require 'rsolr'
  require 'solrizer'

  class Engine < ::Rails::Engine
    config.autoload_paths += %W(#{config.root}/app/models/datastreams)

    isolate_namespace DriDataModels

    config.generators do |g|
      g.test_framework :rspec, fixture: true
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
