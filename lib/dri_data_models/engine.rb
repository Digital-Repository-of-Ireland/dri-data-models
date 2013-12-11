module DriDataModels
  require 'rails'

  class Engine < ::Rails::Engine

  	config.autoload_paths += %W(
        #{config.root}/lib/sufia/models/jobs
      )

    isolate_namespace DriDataModels
  end
end
