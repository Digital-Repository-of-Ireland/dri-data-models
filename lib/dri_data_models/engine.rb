module DriDataModels
  require 'rails'
  require 'hydra/derivatives'
  require 'noid-rails'
  require 'resque/server'
  require 'dri/resque'
  require 'rdf/vocab'

  class Engine < ::Rails::Engine
    config.autoload_paths += %W(#{config.root}/app/models/datastreams)

    isolate_namespace DriDataModels

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

    baseparts = 2 + [(Noid::Rails.config.template.gsub(/\.[rsz]/, '').length.to_f / 2).ceil, 4].min
    baseurl = "#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}"

    ActiveFedora::Base.translate_uri_to_id = lambda do |uri|
                                               uri.to_s.sub(baseurl, '').split('/', baseparts).last
                                             end
    ActiveFedora::Base.translate_id_to_uri = lambda do |id|
                                               "#{baseurl}/#{Noid::Rails.treeify(id)}"
                                             end
  end
end
