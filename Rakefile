# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'bundler/setup'
Bundler::GemHelper.install_tasks
require 'acts_as_geocodable/version'
require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

task :default => :spec

require 'rake/rdoctask'
desc 'Generate documentation for the acts_as_geocodable plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'ActsAsGeocodable'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
