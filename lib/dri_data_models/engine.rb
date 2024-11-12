# frozen_string_literal: true
module DRIDataModels
  require 'rails'
  require 'hydra/derivatives'
  require 'noid-rails'
  require 'resque/server'
  require 'dri/resque'
  require 'rdf/vocab'
  require 'rsolr'
  require 'solrizer'

  class Engine < ::Rails::Engine
    #config.autoload_paths += %W[#{config.root}/app/models/datastreams #{config.root}/lib]
    #config.eager_load_paths += %W[#{config.root}/app/models/datastreams #{config.root}/lib]

    #config.autoload_paths << config.root.join('lib')
    #config.autoload_paths << config.root.join('app','models','datastreams')
    #config.autoload_paths << config.root.join('app','models','dri')
    #config.eager_load_paths << config.root.join('lib')
    #config.eager_load_paths << config.root.join('app','models','datastreams')
    #config.eager_load_paths << config.root.join('app','models','dri')

    isolate_namespace DRIDataModels

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
