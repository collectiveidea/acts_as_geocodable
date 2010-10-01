# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'acts_as_geocodable/version'

Gem::Specification.new do |s|
  s.name = %q{acts_as_geocodable}
  s.version = ::ActsAsGeocodable::VERSION
  s.authors = ["Daniel Morrison", "Brandon Keepers"]
  s.description = %q{Simple geocoding for Rails ActiveRecord models. See the README for more details.}
  s.email = %q{info@collectiveidea.com}
  s.extra_rdoc_files = [
    "README"
  ]
  s.files = Dir.glob("lib/**/*") + %w(CHANGELOG MIT-LICENSE README)
  s.homepage = %q{http://github.com/collectiveidea/acts_as_geocodable}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Simple geocoding for Rails ActiveRecord models}

  s.add_runtime_dependency     'graticule', ">= 2.0.0"
  s.add_development_dependency 'rails'
  s.add_development_dependency 'sqlite3-ruby', '1.2.5'
  s.add_development_dependency 'mysql',        '2.8.1'
  s.add_development_dependency 'rspec',        '~> 2.0.0.beta'
  s.add_development_dependency 'factory_girl'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'ruby-debug'
end

