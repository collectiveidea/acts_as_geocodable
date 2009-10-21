require 'rake'
require 'load_multi_rails_rake_tasks'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the acts_as_geocodable plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the acts_as_geocodable plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'ActsAsGeocodable'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = 'acts_as_geocodable'
    gemspec.summary = 'Simple geocoding for Rails ActiveRecord models'
    gemspec.description = 'Simple geocoding for Rails ActiveRecord models. See the README for more details.'
    gemspec.email = 'info@collectiveidea.com'
    gemspec.homepage = 'http://github.com/collectiveidea/acts_as_geocodable'
    gemspec.authors = ['Daniel Morrison', 'Brandon Keepers']
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end