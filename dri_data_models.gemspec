$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'dri_data_models/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'dri_data_models'
  s.version     = DriDataModels::VERSION
  s.authors     = 'Damien Gallagher'
  s.email       = 'damien.gallagher@nuim.ie'
  s.homepage    = 'http://www.dri.ie'
  s.summary     = 'DRI metadata and data models needed for a DRI Hydra-Head.'
  s.description = 'DRI metadata and data models needed for a DRI Hydra-Head.'

  s.required_ruby_version = '>= 1.9.3'

  s.files = Dir['{app,config,db,lib}/**/*'] + ['Rakefile', 'README.rdoc']
  s.test_files = Dir['{spec}/**/*']

  s.require_paths = ['lib', 'app']

  s.add_dependency 'active-fedora'
  s.add_dependency 'active_fedora-datastreams'
  s.add_dependency 'rails', '~> 5.2'
  s.add_dependency 'hydra-head'
  s.add_dependency 'iso-639'
  s.add_dependency 'hydra-derivatives'
  s.add_dependency 'hydra-file_characterization'
  s.add_dependency 'noid-rails'
  s.add_dependency 'resque'
  s.add_dependency 'iso8601'
  s.add_dependency 'namae'
  s.add_development_dependency 'sqlite3', '~> 1.3', '< 1.4'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'ci_reporter_rspec'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'solr_wrapper', '~> 0.18'
  s.add_development_dependency 'fcrepo_wrapper', '0.9.0'
end
