require 'dri_data_models/engine'
require 'dri_data_models/version'
require 'dri'
require 'namae'
require 'active_fedora/datastreams'

if ENV['RAILS_ENV'] == 'test'
  require 'simplecov'
  SimpleCov.start 'rails'
end

# DriDataModels namespace
module DriDataModels
end
