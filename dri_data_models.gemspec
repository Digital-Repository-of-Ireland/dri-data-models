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

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile", "README.rdoc"]
  s.test_files = Dir["{spec,test}/**/*"]

  s.add_dependency "hydra-head", ">5.0.0"
  s.add_development_dependency "rspec"
  s.add_development_dependency "mocha"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "cucumber"

  s.require_paths = ["lib", "app/models"]
end
