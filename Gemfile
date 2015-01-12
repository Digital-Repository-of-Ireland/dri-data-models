source "http://rubygems.org"

# Declare your gem's dependencies in dri_data_models.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# jquery-rails is used by the dummy application
gem "jquery-rails"

gem "sqlite3"

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use debugger
# gem 'debugger'

# iso-639 is used to convert between different language codes
gem 'iso-639'
#gem 'chronic'

group :development, :test do
  gem 'rcov', :platform => :mri_18
  gem 'simplecov', :platform => [:mri_19, :mri_20]
  gem 'simplecov-rcov', :platform => [:mri_19, :mri_20]

  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-bundler'
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false
  gem 'rspec-rails'
  gem 'mocha'
  gem 'factory_girl_rails'
  gem 'database_cleaner'
  gem 'faker'
  gem 'ci_reporter_cucumber'
  gem 'ci_reporter_rspec'  
  gem 'rspec-legacy_formatters'
end
