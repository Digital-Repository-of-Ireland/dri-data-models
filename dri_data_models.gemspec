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

  s.add_dependency 'rails', '~> 4.2'
  s.add_dependency 'globalize', '~> 5'
  s.add_dependency 'sass-rails', '~> 4.0.3'
  s.add_dependency 'active-fedora', '9.11'
  s.add_dependency 'hydra-head', '~> 9.10'
  s.add_dependency 'hydra-collections'
  s.add_dependency 'iso-639'
  s.add_dependency 'hydra-derivatives', '~> 1.0'
  s.add_dependency 'active_fedora-noid', '~> 1.0'
  s.add_dependency 'resque', '~> 1.23'
  s.add_dependency 'resque-pool', '~> 0.3'
  s.add_dependency 'iso8601'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'
end
