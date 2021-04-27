# frozen_string_literal: true
source 'http://rubygems.org'

# Declare your gem's dependencies in dri_data_models.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

group :test do
  # dri-user-group gem added for the rspec tests
  gem 'paper_trail'
  gem 'user_group', git: 'ssh://git@tracker.dri.ie:2200/drirepo/dri-user-group.git', branch: 'develop'
end
