#!/usr/bin/env rake
require 'jettywrapper'
require 'rspec/core/rake_task'

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

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'DriDataModels'
  rdoc.options << '--line-numbers'
  rdoc.main     = 'README.rdoc'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.include('lib/dri/metadata/*.rb')
  rdoc.rdoc_files.include('app/models/*.rb')
end

require 'ci/reporter/rake/rspec'
RSpec::Core::RakeTask.new(:rspec => ['ci:setup:rspec']) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
  spec.pattern += FileList['spec/*_spec.rb']
end

namespace :jetty do

  desc "return development jetty to its pristine state, as pulled from git"
  task :reset => ['jetty:stop'] do
    system("cd jetty && git reset --hard HEAD && git clean -dfx && cd ..")
    sleep 2
  end

end

desc "Run Continuous Integration"
task :ci => ['ci:setup:rspec'] do
  ENV['environment'] = "test"
  #jetty_params = Jettywrapper.load_config
  #jetty_params[:startup_wait]= 120
  #error = Jettywrapper.wrap(jetty_params) do
    Rake::Task['rspec'].invoke
  #end
  #raise "test failures: #{error}" if error

  Rake::Task["rdoc"].invoke
end

task :default => :rspec
