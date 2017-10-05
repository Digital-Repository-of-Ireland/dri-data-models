require 'dri_data_models/engine'
require 'dri_data_models/version'
require 'dri'

if ENV['RAILS_ENV'] == 'test'
  require 'simplecov'
  SimpleCov.start 'rails'
end

# DriDataModels namespace
module DriDataModels
end
