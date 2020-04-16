#!/usr/bin/env rake
require 'yard'

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

APP_RAKEFILE = File.expand_path("../spec/test_app/Rakefile", __FILE__)
load 'rails/tasks/engine.rake'

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
