#!/usr/bin/env rake
# frozen_string_literal: true
require 'rspec/core/rake_task'
require 'yard'
require 'rubocop/rake_task'
require 'dri/rake_support'

APP_ROOT = File.expand_path("#{File.dirname(__FILE__)}/")

begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

begin
  require 'rdoc/task'
rescue LoadError
  require 'rdoc/rdoc'
  require 'rake/rdoctask'
  RDoc::Task = Rake::RDocTask
end

Bundler::GemHelper.install_tasks
Dir.glob(File.expand_path('../tasks/*.rake', __FILE__)).each do |f|
  load(f)
end

APP_RAKEFILE = File.expand_path("../spec/test_app/Rakefile", __FILE__)
load 'rails/tasks/engine.rake'

require 'ci/reporter/rake/rspec'
require 'rspec/core/rake_task'

desc 'Run RuboCop style checker'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.requires << 'rubocop-rspec'
  task.fail_on_error = true
end

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'DriDataModels'
  rdoc.options << '--line-numbers'
  rdoc.main     = 'README.rdoc'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.include('lib/dri/metadata/*.rb')
  rdoc.rdoc_files.include('app/models/**/*.rb')
end

YARD::Rake::YardocTask.new(:yard) do |t|
  t.files = ['lib/**/*.rb', 'app/models/**/*.rb', 'lib/dri/metadata/*.rb']
end

RSpec::Core::RakeTask.new(:rspec => ["ci:setup:rspec"]) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
  spec.pattern += FileList['spec/*_spec.rb']
end

desc 'Run Continuous Integration'
task :ci do
  ENV['environment'] = 'test'

  with_solr_test_server do
    Rake::Task['app:db:migrate'].invoke
    Rake::Task['app:db:test:prepare'].invoke

    Rake::Task['rspec'].invoke
  end

  Rake::Task['yard'].invoke
end

task default: :rspec
