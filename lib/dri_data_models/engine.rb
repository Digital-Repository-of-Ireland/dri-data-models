module DriDataModels
  require 'rails'

  class Engine < ::Rails::Engine

  	config.autoload_paths += %W(#{config.root}/lib/sufia/models/jobs)
	config.autoload_paths += %W(#{config.root}/app/models/datastreams)

    isolate_namespace DriDataModels
  end
end
