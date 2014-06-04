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

  s.add_dependency "blacklight", "4.5.0"
  s.add_dependency "hydra-head", "6.4.0"
  s.add_dependency "hydra-access-controls", "6.4.0"
  s.add_dependency "iso-639"
  s.add_dependency "sufia-models", "3.4.0"
  s.add_dependency "sqlite3"
  s.add_development_dependency "rspec"
  s.add_development_dependency "mocha"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "cucumber"
  s.add_development_dependency "rdoc"
  s.add_development_dependency "rake"
  s.add_development_dependency "rack-test"
  #s.add_development_dependency "simplecov"

  s.require_paths = ["lib", "app/models"]
end
