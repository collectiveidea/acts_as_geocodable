# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'rubygems'
require 'bundler/setup'
require 'acts_as_geocodable/version'

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :build do
  system "gem build acts_as_geocodable.gemspec"
end
 
task :release => :build do
  system "gem push acts_as_geocodable-#{ActsAsGeocodable::VERSION}.gem"
end

require 'rake/rdoctask'
desc 'Generate documentation for the acts_as_geocodable plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'ActsAsGeocodable'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
