# frozen_string_literal: true
$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'dri_data_models/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'dri_data_models'
  s.version     = DRIDataModels::Version
  s.authors     = ["Damien Gallagher, Stuart Kenny, Kathryn Cassidy, Augustina Martinez"]
  s.email       = 'dri@ria.ie'
  s.homepage    = 'https://www.dri.ie'
  s.summary     = 'DRI metadata and data models needed for the DRI application.'
  s.description = 'DRI metadata and data models needed for the DRI application.'

  s.required_ruby_version = '>= 1.9.3'

  s.files = Dir['{app,config,db,lib}/**/*'] + ['Rakefile', 'README.rdoc']
  s.test_files = Dir['{spec}/**/*']

  s.require_paths = ['lib', 'app']

  s.add_dependency 'om'
  s.add_dependency 'nokogiri', '>= 1.12.5'
  s.add_dependency 'iso-639'
  s.add_dependency 'hydra-derivatives'
  s.add_dependency 'hydra-file_characterization'
  s.add_dependency 'noid-rails'
  s.add_dependency 'resque'
  s.add_dependency 'iso8601'
  s.add_dependency 'namae'
  s.add_dependency 'valkyrie', '~> 3'
  s.add_dependency 'rsolr'
  s.add_dependency 'net-smtp'
  s.add_development_dependency 'sqlite3', '~> 1'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'bixby'

  s.add_development_dependency 'rails', '> 5.1', '< 7.2'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'jquery-rails'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'rspec_junit_formatter'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'solr_wrapper'
  s.add_development_dependency 'sprockets-rails'
end
