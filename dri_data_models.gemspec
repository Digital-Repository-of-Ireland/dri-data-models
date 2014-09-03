$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "dri_data_models/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "dri_data_models"
  s.version     = DriDataModels::VERSION
  s.authors     = "Damien Gallagher"
  s.email       = "damien.gallagher@nuim.ie"
  s.homepage    = "http://www.dri.ie"
  s.summary     = "Hydra metadata and data models needed for a DRI Hydra-Head."
  s.description = "Hydra metadata and data models needed for a DRI Hydra-Head."

  s.required_ruby_version = '>= 1.9.3'

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile", "README.rdoc"]
  s.test_files = Dir["{spec}/**/*"]

  s.require_paths = ["lib", "app"]  

  s.add_dependency "rails", ">= 4.0"
  s.add_dependency 'sass-rails', '~> 4.0.3'
  s.add_dependency "hydra-head", ">= 7.0"
  s.add_dependency "hydra-access-controls"
  s.add_dependency "hydra-collections"
  s.add_dependency "iso-639"
  s.add_dependency "sufia-models", "4.0.0"
end
